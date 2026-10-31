import random

from fastapi import FastAPI, HTTPException, Query

from .db import QUESTIONS
from .models import SubmitRequest
from .scoring import ScoringError, score_answers
from .version import VERSION

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
        return score_answers([(a.id, a.answer) for a in payload.answers], pool_by_id)
    except ScoringError as err:
        raise HTTPException(status_code=422, detail=str(err))


@app.get("/version")
def version():
    return {"version": VERSION}
