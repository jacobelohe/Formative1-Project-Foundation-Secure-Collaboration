import random
from fastapi import FastAPI, HTTPException, Query
from .db import QUESTIONS

app = FastAPI(title="SomaQuiz API")


@app.get("/")
def root():
    return {"status": "ok", "service": "quiz-api"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/subjects")
def list_subjects():
    """Issue #4 — list available subjects."""
    subjects = sorted({q["subject"] for q in QUESTIONS})
    return {"subjects": subjects}


@app.get("/quiz/{subject}")
def get_quiz(
    subject: str,
    count: int = Query(default=5, ge=1, le=20),
):
    """Issue #5 — return N random questions for a subject."""
    pool = [q for q in QUESTIONS if q["subject"] == subject.lower()]
    if not pool:
        raise HTTPException(status_code=404, detail=f"Subject '{subject}' not found.")
    sample = random.sample(pool, min(count, len(pool)))
    return {
        "subject": subject,
        "count": len(sample),
        "questions": [
            {"id": q["id"], "question": q["question"], "options": q["options"]}
            for q in sample
        ],
    }
