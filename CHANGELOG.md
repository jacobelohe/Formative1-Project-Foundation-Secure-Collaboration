# Changelog

How SomaQuiz evolved across the three formatives and the summative. Numbers refer to pull requests.

## Summative: Git-to-production

### Added
- Continuous deployment (`.github/workflows/cd.yml`): a merge to `main` repeats every CI check, builds and scans the image, pushes it to ECR under the commit SHA, deploys with Ansible and verifies the public URL.
- Keyless AWS access for GitHub Actions: a Terraform-managed OIDC role limited to this repository's `production` environment, its ECR repository and the bastion security group.
- PostgreSQL storage for quiz attempts, `GET /stats/{subject}`, and the live commit in `GET /version`.
- Ansible registry login through the instance role, image pull, and rollback to the previous release when a deployment fails.
- `scripts/configure-github.sh` to copy Terraform outputs into the GitHub `production` environment.
- Architecture diagram, operations manual (`README.md`) and this changelog.
- Two-zone VPC with public, private application and isolated database subnets, plus a bastion, load balancer, RDS PostgreSQL and private ECR (#41).
- `/ready` endpoint used by the container health check and CI (#40).

### Changed
- The application VM moved to a private subnet. Ansible reaches it only through the bastion.
- The VM runs an image pulled from ECR; it no longer builds from copied source.
- `ansible/playbook.yml` became `ansible/deploy.yml`, and the inventory group `webservers` became `app_server`.
- `/ready` also checks the database when one is configured.

## Formative 3: Infrastructure as code and DevSecOps

- Terraform for the first AWS network and EC2 host, and Ansible roles for host security, Docker and deployment (#36, #38).
- Dependency, container image and Terraform scans in CI that fail the build, with findings and accepted risks in `SECURITY.md` (#35).

## Formative 2: Containerisation and CI

- Multi-stage, non-root `Dockerfile` and Docker Compose with a network, volume, health check and restart policy (#15, #31).
- GitHub Actions for lint, tests, and an image build with a smoke test (#16, #30).
- `/version` endpoint, used to demonstrate CI rejecting a failing change (#33).
- USSD tests and fixes (#20, #34) and Docker instructions in the README (#32).

## Formative 1: Project foundation

- Project definition, board, issue and PR templates, CODEOWNERS and branch protection.
- Quiz API with subjects, random quizzes and scoring (#18).
- USSD menu (#19).
