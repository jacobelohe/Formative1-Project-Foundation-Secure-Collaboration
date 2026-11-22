from app import main
from fastapi.testclient import TestClient

client = TestClient(main.app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "quiz-api"}

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_readiness():
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json() == {
        "status": "ready",
        "question_count": len(main.QUESTIONS),
    }

def test_readiness_fails_when_questions_are_missing(monkeypatch):
    monkeypatch.setattr(main, "QUESTIONS", [])

    response = client.get("/ready")

    assert response.status_code == 503
    assert response.json() == {"detail": "Quiz questions are not loaded"}

def test_subjects():
    response = client.get("/subjects")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
