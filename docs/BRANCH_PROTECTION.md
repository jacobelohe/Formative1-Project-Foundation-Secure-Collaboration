# Branch Protection for `main`

Settings → Branches → Add branch ruleset / protection rule → branch name pattern `main`.

| Setting | Why it matters |
|---|---|
| Require a pull request before merging | No one can push untested code straight to `main`; every change is visible. |
| Required approvals: **1** | A second person always reads the change (peer review, catches bugs and leaked secrets). |
| Dismiss stale approvals on new commits | An approval can't be reused after the code it approved has changed. |
| Require status checks to pass | CI (lint, tests, build) must be green; add `lint`, `test`, `docker-build` once the workflow has run once. |
| Require branches to be up to date | Prevents merging a PR that would break after combining with newer `main`. |
| Require conversation resolution | Review comments can't be ignored. |
| Include administrators (do not allow bypass) | Rules apply to the team lead too. |
| (Optional) Block force pushes and deletions | Protects history. |

Also enable under Settings → General: Issues, Projects. Under Code security: secret scanning + push protection, Dependabot alerts.

Note: with "1 approval" and an author unable to approve their own PR, another team member must review every PR, which is the point.
