import psycopg
import pytest
from app import main, storage
from fastapi.testclient import TestClient

client = TestClient(main.app)


@pytest.fixture
def database(monkeypatch):
    """Enable storage with in-memory fakes in place of PostgreSQL."""
    saved = []
    monkeypatch.setattr(storage, "is_enabled", lambda: True)
    monkeypatch.setattr(storage, "ping", lambda: None)
    monkeypatch.setattr(storage, "record_attempt", lambda *attempt: saved.append(attempt))
    return saved


def _fail(*_args):
    raise psycopg.OperationalError("database down")


def test_storage_is_disabled_without_postgres_settings(monkeypatch):
    monkeypatch.delenv("DB_SECRET_ARN", raising=False)
    monkeypatch.setenv("DATABASE_URL", "sqlite:///./somaquiz.db")
    assert not storage.is_enabled()


@pytest.mark.parametrize("name,value", [
    ("DATABASE_URL", "postgresql://user@localhost/somaquiz"),
    ("DB_SECRET_ARN", "arn:aws:secretsmanager:eu-west-1:123456789012:secret:db"),
])
def test_storage_is_enabled_by_postgres_settings(monkeypatch, name, value):
    monkeypatch.delenv("DB_SECRET_ARN", raising=False)
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv(name, value)
    assert storage.is_enabled()


def test_connect_refreshes_a_rotated_password(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.setenv("DB_HOST", "db.example.test")
    monkeypatch.setenv("DB_NAME", "somaquiz")
    monkeypatch.setenv("DB_SECRET_ARN", "arn:example")
    monkeypatch.setenv("AWS_REGION", "eu-west-1")
    passwords = iter(["old", "new"])

    class FakeSecrets:
        def get_secret_value(self, SecretId):
            return {"SecretString": f'{{"username": "u", "password": "{next(passwords)}"}}'}

    def fake_connect(**kwargs):
        if kwargs["password"] == "old":
            _fail()
        return kwargs

    storage._credentials.cache_clear()
    monkeypatch.setattr(storage.boto3, "client", lambda *_a, **_k: FakeSecrets())
    monkeypatch.setattr(storage.psycopg, "connect", fake_connect)
    try:
        connection = storage.connect()
    finally:
        storage._credentials.cache_clear()
    assert connection["password"] == "new"
    assert connection["sslmode"] == "require"


def test_readiness_reports_the_database(database):
    assert client.get("/ready").json()["database"] == "connected"


def test_readiness_fails_when_the_database_is_down(database, monkeypatch):
    monkeypatch.setattr(storage, "ping", _fail)
    assert client.get("/ready").status_code == 503


def test_submit_saves_the_attempt(database):
    body = client.post("/quiz/math/submit", json={"answers": [{"id": 1, "answer": "4"}]}).json()
    assert body["saved"] is True
    assert database == [("math", 1, 1)]


def test_submit_still_scores_when_saving_fails(database, monkeypatch):
    monkeypatch.setattr(storage, "record_attempt", _fail)
    body = client.post("/quiz/math/submit", json={"answers": [{"id": 1, "answer": "4"}]}).json()
    assert body["score"] == 1 and body["saved"] is False


def test_stats_need_a_database(monkeypatch):
    monkeypatch.setattr(storage, "is_enabled", lambda: False)
    assert client.get("/stats/math").status_code == 503
    assert client.get("/stats/nope").status_code == 404


def test_stats_come_from_storage(database, monkeypatch):
    stats = {"subject": "math", "attempts": 2, "average_percentage": 75.0}
    monkeypatch.setattr(storage, "subject_stats", lambda subject: stats)
    assert client.get("/stats/Math").json() == stats


def test_version_reports_the_deployed_commit(monkeypatch):
    monkeypatch.setenv("APP_COMMIT", "abc123")
    assert client.get("/version").json()["commit"] == "abc123"
