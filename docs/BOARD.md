# Project Board Plan (GitHub Projects, Kanban)

Columns: **Backlog → In Progress → Done**. Create each card as an Issue (templates in `.github/ISSUE_TEMPLATE`), then add it to the board.
Labels: `feature`, `devops`, `security`, `docs`, `testing`. Milestones: `Formative 1`, `Formative 2`, `Formative 3` (set due dates from the course schedule).

| # | Card | Label | Assignee | Milestone |
|---|---|---|---|---|
| 1 | **Secure repo setup**: .gitignore, LICENSE, CODEOWNERS, PR/issue templates | security | @jacobelohe | Formative 1 |
| 2 | **Enable branch protection on main** (see docs/BRANCH_PROTECTION.md) | security | @jacobelohe | Formative 1 |
| 3 | **README with project description and setup** | docs | @jacobelohe | Formative 1 |
| 4 | As a student, I want to **list subjects** so that I can choose what to practise. | feature | @Mugisha-Joshua | Formative 1 |
| 5 | As a student, I want to **get a quiz of N random questions** so that I can practise. | feature | @Mugisha-Joshua | Formative 1 |
| 6 | As a student, I want to **submit answers and see my score with explanations** so that I learn from mistakes. | feature | @Mugisha-Joshua | Formative 1 |
| 7 | As a student on a feature phone, I want a **USSD-style menu** (subject → quiz) so that I can practise without data. | feature | @Zoulou1 | Formative 1 |
| 8 | **Unit tests** for scoring, quiz selection and USSD menu (pytest) | testing | @Zoulou1 | Formative 1 |
| 9 | As a student, I want to **see my progress per subject** so that I know what to revise. | feature | @Zoulou1 | Formative 2 |
| 10 | **Dockerfile + docker-compose** for quiz-api | devops | @olaniyiolufemi | Formative 1 |
| 11 | **GitHub Actions CI**: lint, test, docker build (names: `lint`, `test`, `docker-build`) | devops | @olaniyiolufemi | Formative 1 |
| 12 | **Terraform skeleton** for cloud deployment (no secrets, remote state later) | devops | @olaniyiolufemi | Formative 2 |
| 13 | As a teacher, I want to **add questions to a subject** so that my class gets relevant practice. | feature | unassigned | Formative 2 |
| 14 | **Dependabot + secret scanning** enabled | security | @jacobelohe | Formative 2 |

Each card needs acceptance criteria (checkboxes) in its description, e.g. card 6: "POST returns score out of N; each wrong answer includes the correct option and explanation; invalid subject returns 404".
