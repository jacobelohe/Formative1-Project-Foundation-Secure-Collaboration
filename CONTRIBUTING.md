# Contributing

`main` is protected. Nobody pushes to it directly.

## Workflow
1. Pick a card on the project board and assign it to yourself; move it to **In Progress**.
2. Update and branch:
   ```bash
   git checkout main && git pull
   git checkout -b feature/<short-task>-<yourname>
   ```
   Prefixes: `feature/`, `fix/`, `devops/`, `docs/`.
3. Commit small and often, in the imperative: `Add quiz scoring function`.
4. Push and open a PR using the template. Write `Closes #<issue>` in the description.
5. Someone else reviews (not the author). Resolve every comment, then merge once CI is green.
6. Delete the branch; the card moves to **Done**.

## Rules
- Never commit `.env`, keys, tokens or passwords. If you do, tell the lead immediately; rotate the secret.
- Keep PRs small (one card = one PR).
- Add or update tests for behaviour you change.
- Stay inside your area to avoid merge conflicts (see `.github/CODEOWNERS`).
