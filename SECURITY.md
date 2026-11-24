# Security Checks

CI runs three security scans: `pip-audit` checks the Python requirements, Trivy checks the built application image, and Trivy checks the Terraform files in `terraform/`. The IaC scan fails on `HIGH` and `CRITICAL` findings. Dependency, IaC, image, test, and lint checks run on pushes to non-main branches and on every pull request.

## Current findings

### Python dependencies and application image

A baseline `pip-audit -r services/quiz-api/requirements-dev.txt` run on 11 November 2026 reported no known vulnerabilities in the runtime or development requirements at that time. The development requirements include the runtime requirements, and both files allow version ranges, so findings can change as new package versions or advisories become available.

The first Trivy image scans on 11 November 2026 found two `HIGH` vulnerabilities in Debian's `zlib1g` package: CVE-2026-76844 and CVE-2026-85091. Trivy reported the fixed package version as `1:1.3.dfsg+really1.3.1-1+deb13u1`. The Dockerfile now updates `zlib1g` from Debian's package repository before building the runtime image. The push and pull-request image scans passed after the update on 13 November 2026. Continue scanning because the base image and vulnerability database can change.

### Terraform configuration

The Trivy v0.76.0 scan currently has three documented, time-limited exceptions, each expiring on 13 December 2026:

- `AWS-0053` on the internet-facing ALB: the public application needs an internet entry point; its EC2 host remains private.
- `AWS-0054` on the HTTP listener: no team domain or matching ACM certificate is available yet. Add HTTPS on port 443, redirect HTTP to HTTPS, then remove this exception once the domain is configured.
- `AWS-0104` on the app security group's TCP 80/443 egress: outbound access through the NAT gateway is currently needed for Ubuntu packages and ECR image pulls. Replace it with suitable private endpoints and a package source before removing the exception.

The bastion no longer has general internet egress, and public subnets no longer auto-assign public IPs. The bastion's explicit public IP remains for SSH access. Revisit all exceptions before they expire and before using this setup beyond the class lab. Do not extend them without reviewing the risk.

The scan also reports `MEDIUM` `AWS-0178` because VPC Flow Logs are not enabled. This is accepted for the non-production lab to avoid extra CloudWatch setup and charges. Enable Flow Logs if the environment needs network-traffic auditing. The CI threshold is `HIGH` and `CRITICAL`, so this finding does not fail the gate.

## How findings are handled

If `pip-audit` finds a vulnerable package, update it to a compatible fixed version and run the tests again. If Trivy finds a vulnerable image package or base image, update the package or image, rebuild the container, and rerun the scan. For IaC findings, make the Terraform configuration more restrictive when practical. If a finding must be accepted, record its ID, severity, scope, reason, and review date; use a time-limited exception rather than silently ignoring it. Recheck accepted findings before their exception expires.
