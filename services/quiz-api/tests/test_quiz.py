from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_subjects_returns_at_least_three():
    subjects = client.get("/subjects").json()
    assert isinstance(subjects, list)
    assert len(subjects) >= 3


def test_quiz_returns_requested_count_without_answers():
    body = client.get("/quiz/math?count=3").json()
    assert body["count"] == 3
    assert all("answer" not in q and "explanation" not in q for q in body["questions"])


def test_quiz_unknown_subject_is_404():
    assert client.get("/quiz/nope").status_code == 404


def test_quiz_count_is_validated():
    assert client.get("/quiz/math?count=0").status_code == 422
    assert client.get("/quiz/math?count=21").status_code == 422


def test_submit_scores_and_explains():
    res = client.post("/quiz/math/submit", json={"answers": [
        {"id": 1, "answer": "4"},   # correct
        {"id": 2, "answer": "20"},  # wrong (30)
    ]}).json()
    assert res["score"] == 1 and res["total"] == 2 and res["percentage"] == 50.0
    assert res["results"][1]["correct_answer"] == "30"
    assert res["results"][1]["explanation"]


def test_submit_rejects_duplicate_ids():
    res = client.post("/quiz/math/submit", json={"answers": [
        {"id": 1, "answer": "4"}, {"id": 1, "answer": "4"},
    ]})
    assert res.status_code == 422


def test_submit_rejects_question_from_other_subject():
    res = client.post("/quiz/math/submit", json={"answers": [{"id": 6, "answer": "x"}]})
    assert res.status_code == 422
