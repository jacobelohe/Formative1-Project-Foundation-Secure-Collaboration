# Security Checks

The CI workflow runs a Python dependency scan with `pip-audit` and scans the built application image with Trivy. Both checks run as part of branch pushes and pull requests targeting `main`.

## Current findings

A baseline `pip-audit -r services/quiz-api/requirements-dev.txt` run on 11 November 2026 reported no known vulnerabilities in the runtime or development requirements at that time. The development requirements include the runtime requirements and both files allow version ranges, so the result can change as new package versions or vulnerability reports become available.

The first Trivy runs on 11 November 2026 found two `HIGH` vulnerabilities in Debian's `zlib1g` package in the app image: CVE-2026-76844 and CVE-2026-85091. Trivy reported the fixed package version as `1:1.3.dfsg+really1.3.1-1+deb13u1`. The final Docker stage now updates `zlib1g` from Debian's package repository before building the runtime image. The next CI run must confirm the fix; this file does not claim the image is clean until that scan passes.

## How findings are handled

If `pip-audit` finds a vulnerable package, update the dependency to a compatible fixed version and run the tests again. If Trivy finds a vulnerable package or base image, update the dependency or base image, rebuild the container, and rerun the scan. For any finding that cannot be fixed yet, record the package or image component, advisory, severity, reason it remains, and the plan to address it.
