import random
from fastapi import FastAPI, HTTPException, Query
from .db import QUESTIONS
from .models import SubmitRequest

app = FastAPI(title="SomaQuiz API")

_by_id: dict[int, dict] = {q["id"]: q for q in QUESTIONS}


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


@app.post("/submit")
def submit_answers(payload: SubmitRequest):
    """Issue #6 — score answers and return per-question explanations."""
    results = []
    correct = 0

    for item in payload.answers:
        q = _by_id.get(item.id)
        if not q:
            raise HTTPException(status_code=404, detail=f"Question id {item.id} not found.")
        is_correct = item.answer.strip() == q["answer"]
        if is_correct:
            correct += 1
        results.append({
            "id": item.id,
            "correct": is_correct,
            "your_answer": item.answer,
            "correct_answer": q["answer"],
            "explanation": q["explanation"],
        })

    total = len(payload.answers)
    return {
        "score": correct,
        "total": total,
        "percentage": round(correct / total * 100, 1) if total else 0,
        "results": results,
    }
