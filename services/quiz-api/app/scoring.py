"""Pure scoring logic, kept separate from the HTTP layer so it can be reused (e.g. by the USSD service) and unit-tested."""


class ScoringError(ValueError):
    """Raised when submitted answers are invalid (duplicate or unknown question ids)."""


def score_answers(answers: list[tuple[int, str]], questions_by_id: dict[int, dict]) -> dict:
    """Score (question_id, answer) pairs against the question bank."""
    ids = [qid for qid, _ in answers]
    if len(ids) != len(set(ids)):
        raise ScoringError("Duplicate question ids in submission.")

    results = []
    correct = 0
    for qid, answer in answers:
        q = questions_by_id.get(qid)
        if q is None:
            raise ScoringError(f"Question id {qid} not found.")
        is_correct = answer.strip() == q["answer"]
        correct += is_correct
        results.append({
            "id": qid,
            "correct": is_correct,
            "your_answer": answer,
            "correct_answer": q["answer"],
            "explanation": q["explanation"],
        })

    total = len(answers)
    return {
        "score": correct,
        "total": total,
        "percentage": round(correct / total * 100, 1) if total else 0,
        "results": results,
    }
