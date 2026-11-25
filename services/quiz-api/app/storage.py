"""PostgreSQL storage for quiz attempts.

Storage is optional: without database settings the API still serves quizzes, which
keeps local runs and CI simple. In production the app connects to RDS and reads the
RDS-managed password from Secrets Manager, so it is never written to disk or to GitHub.
RDS rotates that password, so a failed login is retried once with a fresh secret.
"""

import json
import os
from functools import lru_cache

import boto3
import psycopg

CONNECT_TIMEOUT_SECONDS = 3

_CREATE_TABLE = """
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subject TEXT NOT NULL,
    score INTEGER NOT NULL,
    total INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
"""


def _database_url() -> str | None:
    url = os.getenv("DATABASE_URL", "")
    return url if url.startswith(("postgresql://", "postgres://")) else None


def is_enabled() -> bool:
    return bool(_database_url() or os.getenv("DB_SECRET_ARN"))


@lru_cache(maxsize=1)
def _credentials() -> dict:
    client = boto3.client("secretsmanager", region_name=os.environ["AWS_REGION"])
    secret = client.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])
    return json.loads(secret["SecretString"])


def _open_with_secret() -> psycopg.Connection:
    credentials = _credentials()
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=int(os.getenv("DB_PORT", "5432")),
        dbname=os.environ["DB_NAME"],
        user=credentials["username"],
        password=credentials["password"],
        sslmode="require",
        connect_timeout=CONNECT_TIMEOUT_SECONDS,
    )


def connect() -> psycopg.Connection:
    url = _database_url()
    if url:
        return psycopg.connect(url, connect_timeout=CONNECT_TIMEOUT_SECONDS)
    try:
        return _open_with_secret()
    except psycopg.OperationalError:
        _credentials.cache_clear()
        return _open_with_secret()


def _ensure_table(conn: psycopg.Connection) -> None:
    conn.execute(_CREATE_TABLE)


def ping() -> None:
    """Raise if the database cannot be queried. Also creates the table on first use."""
    with connect() as conn:
        _ensure_table(conn)


def record_attempt(subject: str, score: int, total: int) -> None:
    with connect() as conn:
        _ensure_table(conn)
        conn.execute(
            "INSERT INTO quiz_attempts (subject, score, total) VALUES (%s, %s, %s)",
            (subject, score, total),
        )


def subject_stats(subject: str) -> dict:
    with connect() as conn:
        _ensure_table(conn)
        attempts, average = conn.execute(
            "SELECT count(*), avg(score * 100.0 / total)"
            " FROM quiz_attempts WHERE subject = %s AND total > 0",
            (subject,),
        ).fetchone()
    return {
        "subject": subject,
        "attempts": attempts,
        "average_percentage": round(float(average), 1) if average is not None else None,
    }
