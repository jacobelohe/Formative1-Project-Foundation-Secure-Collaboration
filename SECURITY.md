# Security Checks

CI runs three security scans: `pip-audit` checks the Python requirements, Trivy checks the built application image, and Trivy checks the Terraform files in `terraform/`. The IaC scan fails on `HIGH` and `CRITICAL` findings. Dependency, IaC, image, test, and lint checks run on pushes to non-main branches and on every pull request.

## Current findings

### Python dependencies and application image

A baseline `pip-audit -r services/quiz-api/requirements-dev.txt` run on 11 November 2026 reported no known vulnerabilities in the runtime or development requirements at that time. The development requirements include the runtime requirements, and both files allow version ranges, so findings can change as new package versions or advisories become available.

The first Trivy image scans on 11 November 2026 found two `HIGH` vulnerabilities in Debian's `zlib1g` package: CVE-2026-76844 and CVE-2026-85091. Trivy reported the fixed package version as `1:1.3.dfsg+really1.3.1-1+deb13u1`. The Dockerfile now updates `zlib1g` from Debian's package repository before building the runtime image. The push and pull-request image scans passed after the update on 13 November 2026. Continue scanning because the base image and vulnerability database can change.

### Terraform configuration

A full Trivy v0.76.0 scan of `terraform/` on 13 November 2026 found two `CRITICAL` `AWS-0104` findings on the outbound security-group rules in `terraform/modules/network/main.tf`. Both rules target `0.0.0.0/0`, one for TCP 80 and one for TCP 443. These ports are used for OS updates and container image pulls. The destination range is still broad, so the risk is accepted temporarily for this student lab. The Terraform resource has a time-limited Trivy exception for `AWS-0104` through 13 December 2026. The rule remains limited to those two TCP ports; it does not allow all protocols or ports. Revisit the exception before it expires and before using this setup for production.

The same scan found one `MEDIUM` `AWS-0178` recommendation because VPC Flow Logs are not enabled. This is accepted for the non-production lab to avoid adding CloudWatch logging and its extra setup and possible charges. Enable Flow Logs if the environment is used beyond the class project or needs network-traffic auditing. The configured CI threshold is `HIGH` and `CRITICAL`, so this `MEDIUM` finding is reported by a full scan but does not fail the gate.

## How findings are handled

If `pip-audit` finds a vulnerable package, update it to a compatible fixed version and run the tests again. If Trivy finds a vulnerable image package or base image, update the package or image, rebuild the container, and rerun the scan. For IaC findings, make the Terraform configuration more restrictive when practical. If a finding must be accepted, record its ID, severity, scope, reason, and review date; use a time-limited exception rather than silently ignoring it. Recheck accepted findings before their exception expires.
