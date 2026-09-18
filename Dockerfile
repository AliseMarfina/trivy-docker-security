FROM python:3.9-slim

WORKDIR /app

# Some of the intentionally old packages in requirements.txt predate Python 3.9
# and ship no prebuilt wheel for it, so pip has to compile them from source.
# A -slim image has no compiler by default, so this is required for
# `make build` to succeed at all.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/app.py .

EXPOSE 5000

# --- "BEFORE" state (default, active): container runs as root.                ---
# --- `trivy config .` reports DS-0002 (HIGH) and exits 1 — see README.        ---
# ---                                                                          ---
# --- "AFTER" state (live remediation, shown during the demo): uncomment the   ---
# --- two lines below and rerun `make scan-config` — 0 misconfigurations,      ---
# --- exit code 0. This is the live "fix it on stage" moment of the demo.      ---
# RUN useradd --create-home --uid 1000 appuser
# USER appuser

CMD ["python", "app.py"]