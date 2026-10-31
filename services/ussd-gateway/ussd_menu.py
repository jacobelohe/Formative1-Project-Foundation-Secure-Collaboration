"""A simple USSD-style menu for SomaQuiz."""

SUBJECTS = {
    "1": "math",
    "2": "english",
    "3": "biology",
    "4": "history",
}

QUESTIONS = {
    "math": [
        {
            "question": "What is 2 + 2?",
            "options": ["3", "4", "5"],
        },
        {
            "question": "What is 3 x 3?",
            "options": ["6", "9", "12"],
        },
    ],
    "english": [
        {
            "question": "Choose the noun: The farmer plants maize.",
            "options": ["farmer", "plants", "the"],
        },
        {
            "question": "What is the opposite of early?",
            "options": ["late", "quick", "soon"],
        },
    ],
    "biology": [
        {
            "question": "Which organ pumps blood?",
            "options": ["Lungs", "Heart", "Kidney"],
        },
        {
            "question": "What do plants need for photosynthesis?",
            "options": ["Light", "Sound", "Plastic"],
        },
    ],
    "history": [
        {
            "question": "In which year did Rwanda gain independence?",
            "options": ["1960", "1962", "1964"],
        },
        {
            "question": "Who was the first President of Kenya?",
            "options": ["Daniel arap Moi", "Jomo Kenyatta", "Uhuru Kenyatta"],
        },
    ],
}


def handle_session(session_text):
    """Return the next screen for a USSD session."""
    if not isinstance(session_text, str):
        return "END Invalid input. Please start again."

    session_text = session_text.strip()

    if session_text == "":
        return show_subjects()

    parts = session_text.split("*")
    subject_number = parts[0]
    subject = SUBJECTS.get(subject_number)

    if subject is None:
        return "END Invalid subject. Please start again."

    if len(parts) == 1:
        return show_questions(subject)

    if len(parts) != 2:
        return "END Invalid session. Please start again."

    question_number = parts[1]

    if not question_number.isdecimal():
        return "END Invalid question. Please start again."

    question_position = int(question_number) - 1
    subject_questions = QUESTIONS[subject]

    if question_position < 0 or question_position >= len(subject_questions):
        return "END Invalid question. Please start again."

    return show_question(subject, question_position)


def show_subjects():
    message = "CON SomaQuiz\nChoose a subject:\n"

    for number, subject in SUBJECTS.items():
        message += f"{number}. {subject.title()}\n"

    return message.rstrip()


def show_questions(subject):
    message = f"CON {subject.title()}\nChoose a question:\n"

    for number in range(len(QUESTIONS[subject])):
        message += f"{number + 1}. Question {number + 1}\n"

    return message.rstrip()


def show_question(subject, question_position):
    question = QUESTIONS[subject][question_position]
    message = (
        f"END {subject.title()}\n"
        f"Question {question_position + 1}: {question['question']}\n"
    )

    for number, option in enumerate(question["options"], start=1):
        message += f"{number}. {option}\n"

    return message.rstrip()
