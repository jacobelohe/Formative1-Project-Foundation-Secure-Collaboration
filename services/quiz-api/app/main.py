import logging
import os
import random

from fastapi import FastAPI, HTTPException, Query

from . import storage
from .db import QUESTIONS
from .models import SubmitRequest
from .scoring import ScoringError, score_answers
from .version import VERSION

logger = logging.getLogger("uvicorn.error")

app = FastAPI(title="SomaQuiz API")


def _questions_for(subject: str) -> list[dict]:
    pool = [q for q in QUESTIONS if q["subject"] == subject.lower()]
    if not pool:
        raise HTTPException(status_code=404, detail=f"Subject '{subject}' not found.")
    return pool


@app.get("/")
def root():
    return {"status": "ok", "service": "quiz-api"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def readiness():
    """Report whether quiz data is loaded and the database, if configured, responds."""
    if not QUESTIONS:
        raise HTTPException(status_code=503, detail="Quiz questions are not loaded")
    body = {"status": "ready", "question_count": len(QUESTIONS)}
    if storage.is_enabled():
        try:
            storage.ping()
        except Exception as err:
            logger.exception("Database readiness check failed")
            raise HTTPException(status_code=503, detail="Database is not available") from err
        body["database"] = "connected"
    return body


@app.get("/subjects")
def list_subjects():
    """Issue #4 — list available subjects."""
    return sorted({q["subject"] for q in QUESTIONS})


@app.get("/quiz/{subject}")
def get_quiz(
    subject: str,
    count: int = Query(default=5, ge=1, le=20),
):
    """Issue #5 — return N random questions for a subject (answers hidden)."""
    pool = _questions_for(subject)
    sample = random.sample(pool, min(count, len(pool)))
    return {
        "subject": subject.lower(),
        "count": len(sample),
        "questions": [
            {"id": q["id"], "question": q["question"], "options": q["options"]}
            for q in sample
        ],
    }


@app.post("/quiz/{subject}/submit")
def submit_answers(subject: str, payload: SubmitRequest):
    """Issue #6 — score answers and return per-question explanations."""
    pool_by_id = {q["id"]: q for q in _questions_for(subject)}
    try:
        result = score_answers([(a.id, a.answer) for a in payload.answers], pool_by_id)
    except ScoringError as err:
        raise HTTPException(status_code=422, detail=str(err))
    if storage.is_enabled():
        # The student still gets a score if saving fails; "saved" tells the client.
        try:
            storage.record_attempt(subject.lower(), result["score"], result["total"])
            result["saved"] = True
        except Exception:
            logger.exception("Saving the quiz attempt failed")
            result["saved"] = False
    return result


@app.get("/stats/{subject}")
def subject_stats(subject: str):
    """Issue #9 — attempts and average score for a subject, read from the database."""
    _questions_for(subject)
    if not storage.is_enabled():
        raise HTTPException(status_code=503, detail="Statistics need a database")
    try:
        return storage.subject_stats(subject.lower())
    except Exception as err:
        logger.exception("Reading statistics failed")
        raise HTTPException(status_code=503, detail="Database is not available") from err


@app.get("/version")
def version():
    body = {"version": VERSION}
    # Set by the deployment so the CD pipeline can confirm which commit is live.
    if commit := os.getenv("APP_COMMIT"):
        body["commit"] = commit
    return body
