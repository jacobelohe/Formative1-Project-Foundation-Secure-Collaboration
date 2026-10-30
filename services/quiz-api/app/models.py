from pydantic import BaseModel


class AnswerItem(BaseModel):
    id: int
    answer: str


class SubmitRequest(BaseModel):
    answers: list[AnswerItem]
