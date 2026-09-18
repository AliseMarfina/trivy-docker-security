IMAGE_NAME := trivy-demo-app
TAG        := latest

.PHONY: build scan-config scan-image scan-fail demo clean

## Build the demo image
build:
	docker build -t $(IMAGE_NAME):$(TAG) .

## Scan the Dockerfile itself for misconfigurations (no image needed).
## NOTE: exits 1 by design while the container still runs as root (DS-0002).
## That IS the edge case — see README "Two states" for the live fix.
scan-config:
	trivy config .

## Scan the built image, gated by trivy.yaml (severity, ignore-unfixed, exit-code)
scan-image: build
	trivy image $(IMAGE_NAME):$(TAG)

## Same as scan-image but forces the "vulnerability found -> pipeline fails" edge case,
## ignoring .trivyignore so CVE-2018-18074 is reported again for the demo.
scan-fail: build
	trivy image --exit-code 1 --severity CRITICAL,HIGH --ignorefile /dev/null $(IMAGE_NAME):$(TAG); \
	echo "Exit code: $$?"

## Full walkthrough used in the Live Demo: build -> config scan -> image scan -> failure case
demo: build scan-config scan-image
	@echo "\n--- Now demonstrating the failure edge case ---\n"
	$(MAKE) scan-fail

clean:
	docker rmi -f $(IMAGE_NAME):$(TAG) 2>/dev/null || true