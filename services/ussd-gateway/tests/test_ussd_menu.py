import pytest
from ussd_menu import handle_session


def test_empty_session_shows_subjects():
    response = handle_session("")

    assert response.startswith("CON SomaQuiz")
    assert "1. Math" in response
    assert "2. English" in response
    assert "3. Biology" in response
    assert "4. History" in response


@pytest.mark.parametrize(
    ("selection", "subject"),
    [
        ("1", "Math"),
        ("2", "English"),
        ("3", "Biology"),
        ("4", "History"),
    ],
)
def test_subject_selection_shows_questions(selection, subject):
    response = handle_session(selection)

    assert response.startswith(f"CON {subject}")
    assert "Choose a question:" in response
    assert "1. Question 1" in response
    assert "2. Question 2" in response


def test_question_screen_shows_question_and_ends_session():
    response = handle_session("1*2")

    assert response.startswith("END Math")
    assert "Question 2: What is 3 x 3?" in response
    assert "1. 6" in response
    assert "2. 9" in response


@pytest.mark.parametrize(
    "session_text",
    ["abc", "5", "1*x", "1*3", "1*²", "1*2*3"],
)
def test_invalid_session_is_handled(session_text):
    response = handle_session(session_text)

    assert response.startswith("END")
    assert "Invalid" in response
