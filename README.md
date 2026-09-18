# Automated Docker Container Security Scanning with Trivy

Quick-Start Workshop demo: Trivy deployed from scratch against a small,
intentionally vulnerable Flask application, wired into a Makefile and a
GitHub Actions pipeline.

## What problem this solves

Container images silently inherit vulnerable OS packages and outdated
application dependencies. Without an automated gate, these ship to
production unnoticed until an incident or an audit finds them. Trivy scans
a Dockerfile, a filesystem, or a built image for known CVEs and
misconfigurations and can fail a CI job the moment something above an
agreed severity threshold is found.

## Repository layout

```
.
├── app/
│   ├── app.py              # trivial Flask app
│   └── requirements.txt    # pinned to old, vulnerable versions on purpose
├── Dockerfile               # builds the demo image (root user, on purpose)
├── trivy.yaml                # scan policy: severity, exit code, ignore rules
├── .trivyignore               # one CVE accepted as risk, with justification
├── Makefile                   # build / scan-config / scan-image / scan-fail / demo
└── .github/workflows/trivy-scan.yml   # CI gate: config scan + image scan
```

## Prerequisites

- Docker
- [Trivy](https://aquasecurity.github.io/trivy) installed locally
  (`brew install trivy`, or see the official install docs for your OS)

## Running the demo

```bash
git clone <YOUR_GITHUB_REPO_URL>
cd trivy-docker-security

make build          # docker build
make scan-config    # trivy config .        -> Dockerfile misconfigurations
make scan-image      # trivy image ...       -> CVEs in the built image
make scan-fail        # forces the failure edge case (exit code 1)
```

`make demo` runs all of the above in sequence — this is the exact
walkthrough used in the Live Demo.

## Configuration walkthrough

- **`Dockerfile`** — based on `python:3.9-slim` and installs
  `app/requirements.txt` as-is, with no `USER` instruction, so the
  container runs as root. This is a deliberate, realistic misconfiguration
  for `trivy config` to catch (check `DS-0002`).
- **`app/requirements.txt`** — pins `Flask`, `requests`, `Pillow`, and
  `PyYAML` to old releases so `trivy image` / `trivy fs` reliably finds
  known, fixed CVEs in a real vulnerability database.
- **`trivy.yaml`** — the scan policy: only `CRITICAL`/`HIGH` are reported,
  `exit-code: 1` turns findings into a failed job, `ignore-unfixed: true`
  skips issues with no available patch, and `ignorefile` points at
  `.trivyignore`.
- **`.trivyignore`** — one CVE (`CVE-2018-18074`, a `requests`
  Proxy-Authorization header leak) accepted as risk with a reason,
  reviewer, and expiry date, rather than silently ignored.
- **`.github/workflows/trivy-scan.yml`** — runs a config scan
  (advisory) and then an image scan (blocking) on every push/PR, and
  uploads results as SARIF to the GitHub Security tab.

## Edge case demonstrated live

`make scan-fail` re-runs `trivy image` with `.trivyignore` bypassed and
`--exit-code 1`, so a genuine CRITICAL/HIGH finding is reported and the
command exits non-zero — the same way the CI job would fail a pull
request. `echo $?` right after shows the non-zero exit code driving that
failure.

## Notes on reproducing the scans

`trivy config` (Dockerfile misconfiguration scan) needs no external
registry access beyond Trivy's own release and runs fully offline once
installed. `trivy image` / `trivy fs` (CVE scans) need one-time network
access to pull Trivy's vulnerability database; run them on a machine
with normal internet access (this is expected — CI runners have it by
default, see the workflow above).
