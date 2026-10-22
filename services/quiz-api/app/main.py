from fastapi import FastAPI

app = FastAPI(title="SomaQuiz Quiz API")

@app.get("/")
def read_root():
    return {"status": "ok", "service": "quiz-api"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/subjects")
def get_subjects():
    return []
