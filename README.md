# SomaQuiz

> Exam practice that works on any phone, with or without a smartphone.

[![CI](https://github.com/jacobelohe/Formative1-Project-Foundation-Secure-Collaboration/actions/workflows/ci.yml/badge.svg)](https://github.com/jacobelohe/Formative1-Project-Foundation-Secure-Collaboration/actions/workflows/ci.yml)

---

## 📋 Team Participation Sheet

> **[👉 View Team Participation Sheet](https://docs.google.com/spreadsheets/d/1T84KL2_JWtcByxihPB16qP5hJUZ8BI4qkjxJ-HTExCI/edit?usp=sharing)**
>
> 📎 Local copy: [SomaQuiz Team Task Sheet - Advanced DevOps.xlsx](SomaQuiz%20Team%20Task%20Sheet%20-%20Advanced%20DevOps.xlsx)

---

## African Context

Millions of secondary-school students across Africa sit national exams (WAEC, KCSE, NECTA, Rwanda National Exams, and others), yet quality past-paper practice is expensive, scattered across heavy PDFs, or locked behind costly data bundles. Many students own only a low-end or feature phone, and phones are often shared within a household. SomaQuiz offers lightweight quizzes with instant marking and explanations, delivered through a small web app **and** a USSD-style text menu that needs no smartphone and almost no data. ("Soma" means "read/study" in Swahili.)

## Team Members

| Name | Role | GitHub | Student ID |
|---|---|---|---|
| Jacob Ndayishimiye | Team lead: repo security, CI/branch rules, documentation | [@jacobelohe](https://github.com/jacobelohe) | _add_ |
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
- Docker with Compose v2 (optional, to run in a container; see [Run with Docker Compose](#run-with-docker-compose))

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

### Run with Docker Compose

The whole service starts with one command. Docker builds the image from the root `Dockerfile` (multi-stage, non-root user, health check).

```bash
cp .env.example .env          # compose reads its settings from .env (git-ignored)
docker compose up --build     # build the image and start the API on http://localhost:8000
```

Useful commands:

```bash
docker compose up -d                 # run in the background
docker compose ps                    # shows the container and its health status
docker compose logs -f quiz-api      # follow the logs
docker compose down                  # stop and remove the containers (keeps the data volume)
docker compose down -v               # also delete the named data volume
```

Check it is healthy:

```bash
curl http://localhost:8000/health    # {"status":"healthy"}
```

Run the tests on your machine (they also run in CI):

```bash
pip install -r services/quiz-api/requirements-dev.txt
PYTHONPATH=services/quiz-api pytest
```

### Usage

```bash
curl http://localhost:8000/subjects
curl "http://localhost:8000/quiz/math?count=5"
curl -X POST http://localhost:8000/quiz/math/submit \
  -H "Content-Type: application/json" \
  -d '{"answers":[{"id":1,"answer":"4"},{"id":2,"answer":"30"}]}'
```

## Continuous Integration

Every push to a branch other than `main`, and every pull request that targets `main`, runs [the CI workflow](.github/workflows/ci.yml):

| Job | What it does | Fails when |
|---|---|---|
| `lint` | `ruff check .` | any lint error |
| `test` | `pytest` for the quiz API and the USSD menu | any test fails |
| `docker-build` | builds the image with Docker Compose, starts it and calls `/health` | the build fails or the container is not healthy |

`lint`, `test` and `docker-build` are **required status checks** on `main`, so a pull request cannot be merged until all three pass and it has one approving review.

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
├── Dockerfile             # Multi-stage image for quiz-api
├── docker-compose.yml     # Local orchestration (network, volume, health check)
├── .dockerignore
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
