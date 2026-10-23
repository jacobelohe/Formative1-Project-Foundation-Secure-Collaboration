import sys
from pathlib import Path

import pytest

sys.path.append(str(Path(__file__).resolve().parents[1]))

from ussd_menu import handle_session  # noqa: E402


def test_empty_session_shows_subjects():
    response = handle_session("")

    assert response.startswith("CON SomaQuiz")
    assert "1. Mathematics" in response
    assert "2. English" in response


def test_subject_selection_shows_questions():
    response = handle_session("1")

    assert "CON Mathematics" in response
    assert "1. Question 1" in response
    assert "2. Question 2" in response


def test_question_selection_shows_question():
    response = handle_session("1*2")

    assert "Question 2: What is 3 x 3?" in response
    assert "1. 6" in response
    assert "2. 9" in response


@pytest.mark.parametrize("session_text", ["abc", "4", "1*x", "1*3", "1*2*3"])
def test_invalid_session_is_handled(session_text):
    response = handle_session(session_text)

    assert response.startswith("END")
    assert "Invalid" in response
