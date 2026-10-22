# Team Guide: who does what and how to start

You each own an area, so you rarely touch the same files. Read [CONTRIBUTING.md](../CONTRIBUTING.md) first.

## Joshua (@Mugisha-Joshua): Backend, cards 4-6
Create `services/quiz-api/` with a FastAPI app:
- `GET /subjects`, `GET /quiz/{subject}?count=5`, `POST /quiz/{subject}/submit`
- Question data in `services/quiz-api/data/questions.json` (3+ subjects, 5+ questions each, each with options, answer, explanation)
- `requirements.txt`; keep scoring in its own module (`scoring.py`) so it is easy to test.
- Update the README "Getting Started" if commands differ.
Branch: `feature/quiz-api-joshua`.

## Ewing (@Zoulou1): USSD + tests, cards 7-9
- `services/ussd-gateway/`: a function/endpoint that takes the session text (e.g. `""`, `"1"`, `"1*2"`) and returns the next menu text (level 1: subjects, level 2: questions). Start with a standalone module; call quiz-api later.
- pytest tests for USSD and (once merged) scoring.
Branch: `feature/ussd-menu-ewing`, then `test/unit-tests-ewing`.

## Olaniyi (@olaniyiolufemi): DevOps, cards 10-12
- `services/quiz-api/Dockerfile`, root `docker-compose.yml`.
- `.github/workflows/ci.yml` with jobs named `lint` (ruff), `test` (pytest), `docker-build`. Then Jacob adds these as required checks.
- `infra/terraform/` skeleton: provider, variables, outputs. No real secrets; `*.tfstate` is already ignored.
Branch: `devops/docker-olaniyi`, `devops/ci-olaniyi`.

## Jacob (lead): cards 1-3, 14
Repo hygiene, branch protection, board, docs, participation sheet. Reviews PRs.

## Review rotation (so approvals are real)
Joshua's PRs → Ewing · Ewing's → Olaniyi · Olaniyi's → Joshua · Jacob's → anyone.

## Getting started (everyone)
1. Accept the repo invite email from GitHub.
2. `git clone git@github.com:jacobelohe/Formative1-Project-Foundation-Secure-Collaboration.git`
3. Set your identity: `git config user.name "Your Name"` and `git config user.email "<email used on GitHub>"`.
4. Create your branch, do your card, open a PR.
5. Fill in your own row of the participation sheet honestly, with your real work and real meeting attendance.

You are free to use AI tools to help write your code (the assignment permits it), but make sure you understand what you submit; you may be asked about it.
