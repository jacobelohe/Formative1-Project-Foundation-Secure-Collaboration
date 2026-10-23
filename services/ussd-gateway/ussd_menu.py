"""A simple USSD-style menu for SomaQuiz."""

SUBJECTS = {
    "1": "Mathematics",
    "2": "English",
    "3": "Science",
}

QUESTIONS = {
    "1": [
        {
            "question": "What is 2 + 2?",
            "options": ["3", "4", "5"],
        },
        {
            "question": "What is 3 x 3?",
            "options": ["6", "9", "12"],
        },
    ],
    "2": [
        {
            "question": "Choose the noun: The farmer plants maize.",
            "options": ["farmer", "plants", "the"],
        },
        {
            "question": "What is the opposite of early?",
            "options": ["late", "quick", "soon"],
        },
    ],
    "3": [
        {
            "question": "Which organ pumps blood?",
            "options": ["Lungs", "Heart", "Kidney"],
        },
        {
            "question": "What do plants need for photosynthesis?",
            "options": ["Light", "Sound", "Plastic"],
        },
    ],
}


def handle_session(session_text):
    """Return the next menu screen for a USSD session."""
    if not isinstance(session_text, str):
        return "END Invalid input. Please start again."

    session_text = session_text.strip()

    if session_text == "":
        return show_subjects()

    parts = session_text.split("*")

    if len(parts) == 1:
        subject_number = parts[0]
        if subject_number not in SUBJECTS:
            return "END Invalid subject. Please start again."
        return show_questions(subject_number)

    if len(parts) == 2:
        subject_number = parts[0]
        question_number = parts[1]

        if subject_number not in SUBJECTS:
            return "END Invalid subject. Please start again."

        if not question_number.isdigit():
            return "END Invalid question. Please start again."

        question_position = int(question_number) - 1
        subject_questions = QUESTIONS[subject_number]

        if question_position < 0 or question_position >= len(subject_questions):
            return "END Invalid question. Please start again."

        return show_question(subject_number, question_position)

    return "END Invalid session. Please start again."


def show_subjects():
    message = "CON SomaQuiz\nChoose a subject:\n"
    for number, subject in SUBJECTS.items():
        message += f"{number}. {subject}\n"
    return message.rstrip()


def show_questions(subject_number):
    message = f"CON {SUBJECTS[subject_number]}\nChoose a question:\n"
    for number in range(len(QUESTIONS[subject_number])):
        message += f"{number + 1}. Question {number + 1}\n"
    return message.rstrip()


def show_question(subject_number, question_position):
    question = QUESTIONS[subject_number][question_position]
    message = (
        f"CON {SUBJECTS[subject_number]}\n"
        f"Question {question_position + 1}: {question['question']}\n"
    )

    for number, option in enumerate(question["options"], start=1):
        message += f"{number}. {option}\n"

    return message.rstrip()
