from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "quiz-api"}

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_subjects():
    response = client.get("/subjects")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
