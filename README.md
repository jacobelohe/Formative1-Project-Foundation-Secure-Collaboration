# SomaQuiz

> Exam practice that works on any phone, with or without a smartphone.

---

## 📋 Team Participation Sheet

> **[👉 View Team Participation Sheet](https://docs.google.com/spreadsheets/d/1T84KL2_JWtcByxihPB16qP5hJUZ8BI4qkjxJ-HTExCI/edit?usp=sharing)**

---

## African Context

Millions of secondary-school students across Africa sit national exams (WAEC, KCSE, NECTA, Rwanda National Exams, and others), yet quality past-paper practice is expensive, scattered across heavy PDFs, or locked behind costly data bundles. Many students own only a low-end or feature phone, and phones are often shared within a household. SomaQuiz offers lightweight quizzes with instant marking and explanations, delivered through a small web app **and** a USSD-style text menu that needs no smartphone and almost no data. ("Soma" means "read/study" in Swahili.)

## Team Members

| Name | Role | GitHub | Student ID |
|---|---|---|---|
| Jacob Elohe | Team lead: repo security, CI/branch rules, documentation | [@jacobelohe](https://github.com/jacobelohe) | _add_ |
| Joshua Ochel Mugisha | Backend: quiz API and scoring | [@Mugisha-Joshua](https://github.com/Mugisha-Joshua) | _add_ |
| Ewing Keylan | USSD menu, tests | [@Zoulou1](https://github.com/Zoulou1) | _add_ |
| Olaniyi Olufemi | DevOps: Docker, GitHub Actions, Terraform | [@olaniyiolufemi](https://github.com/olaniyiolufemi) | _add_ |

## Project Overview

SomaQuiz lets a student pick a subject, answer a short set of multiple-choice questions, and receive a score with an explanation for every answer. The same quiz engine is exposed over HTTP (for a web front end) and through a USSD-style text menu so students on feature phones can practise too.

The code is organised as small, independent services (`quiz-api`, `ussd-gateway`) behind clear interfaces, so each can be containerised and scaled separately as the project grows.

### Target Users
- Secondary-school students preparing for national exams, especially on low-end or shared phones and limited data.
- Teachers who want to add and curate question banks for their class.

### Core Features
- **Subject list**: browse available subjects.
- **Quiz generation**: get N random questions for a subject.
- **Instant scoring**: submit answers and receive a score plus per-question explanations.
- **USSD-style menu**: navigable text menu (2+ levels) for feature phones.
- **Progress stats**: see how a student is doing per subject.

## Technology Stack

- **Backend**: Python 3.12, FastAPI
- **Frontend**: vanilla HTML/CSS/JavaScript
- **Database**: JSON seed data, then SQLite (Postgres later)
- **Other**: pytest, Docker, GitHub Actions, Terraform

## Getting Started

### Prerequisites
- Python 3.12+
- Git
- Docker (optional, for the container run)

### Installation

1. Clone the repository
```bash
git clone git@github.com:jacobelohe/Formative1-Project-Foundation-Secure-Collaboration.git
cd Formative1-Project-Foundation-Secure-Collaboration
```

2. Install dependencies
```bash
cd services/quiz-api
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp ../../.env.example ../../.env
```

3. Run the application
```bash
uvicorn app.main:app --reload
```
Then open http://localhost:8000/docs.

> The setup commands above become fully runnable once the `quiz-api` branch (board card #4) is merged. Joshua keeps this section accurate.

### Usage

```bash
curl http://localhost:8000/subjects
curl "http://localhost:8000/quiz/math?count=5"
```

## Project Structure

```
.
├── .github/               # CODEOWNERS, PR/issue templates, CI workflows
├── docs/                  # Board plan, branch protection, team guide
├── frontend/              # Static web client
├── infra/terraform/       # Infrastructure as code
├── services/
│   ├── quiz-api/          # Quiz + scoring service (FastAPI)
│   └── ussd-gateway/      # USSD menu service
├── docker-compose.yml
└── README.md
```

## Collaboration & Security

- `main` is protected: PRs only, 1 approval, passing CI. See [docs/BRANCH_PROTECTION.md](docs/BRANCH_PROTECTION.md).
- Workflow and branch naming: [CONTRIBUTING.md](CONTRIBUTING.md).
- Secrets live in `.env` (git-ignored); only `.env.example` is committed.

## Links

- [Project Board](https://github.com/users/jacobelohe/projects/1)
- [Board plan](docs/BOARD.md)

## License

MIT License. See [LICENSE](LICENSE).
