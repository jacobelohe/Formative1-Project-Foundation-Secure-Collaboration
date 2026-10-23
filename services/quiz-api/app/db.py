import json
from pathlib import Path

_path = Path(__file__).parent / "data" / "questions.json"
QUESTIONS: list[dict] = json.loads(_path.read_text(encoding="utf-8"))
