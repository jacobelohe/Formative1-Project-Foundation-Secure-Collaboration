from fastapi import FastAPI
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
