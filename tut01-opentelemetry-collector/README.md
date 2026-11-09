# OpenTelemetry Collector tutorial: from zero to a working pipeline

Companion code for the video *OpenTelemetry Collector Tutorial: From Zero to
a Working Pipeline*. Every command and output in the video comes from
running this folder. Tested 2026-11-09 with:

| Component | Version |
|---|---|
| OpenTelemetry Collector (contrib) | 0.164.0 |
| Jaeger | 2.22.0 |
| telemetrygen | v0.164.0 |
| Docker / Compose | 29.9 / 5.7 |

## Steps (the video's chapters)

```bash
./run.sh step1            # 1. Run the Collector: OTLP receiver, debug exporter
./run.sh send             # 2. Send a trace: "resource spans": 1, "spans": 2
./run.sh step3            # 3. Add processors: memory_limiter, then batch
./run.sh step4_mistake    # 4. The silent mistake: exporter defined, not in the pipeline
SERVICE=checkout-step4 ./run.sh send && ./run.sh jaeger   # nothing reaches Jaeger, no error
./run.sh step5            # 5. Wire otlp_grpc/jaeger into the pipeline
SERVICE=checkout ./run.sh send && ./run.sh jaeger
./run.sh step6_load       # 6. Low memory limit + the Collector's own metrics
./run.sh load && ./run.sh metrics
./run.sh down
```

Jaeger UI: http://localhost:16686

## Things this tutorial found while testing

- An exporter that is defined but not listed in a pipeline is ignored
  without a warning or an error.
- In 0.164.0 the `otlp` exporter name is a deprecated alias: use `otlp_grpc`.
- In Jaeger 2.22 the old `/api/services` path returns 404; the query API
  is `/api/v3/...`.
- The Collector's own metrics on :8888 are not reachable from another
  container until `service.telemetry.metrics.readers` binds them to 0.0.0.0.

## Step 7 (full config): scrub, metrics, health check

```bash
./run.sh step7_full
# a span with two sensitive attributes: user.email is deleted, user.id is hashed (SHA-256)
docker run --rm --network lab_default ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.164.0 \
  traces --otlp-insecure --otlp-endpoint otel-collector:4317 --traces 1 --service checkout \
  --telemetry-attributes 'user.email="ana@example.com"' --telemetry-attributes 'user.id="42"'
curl http://localhost:13133/   # {"status":"Server available", ...}
```
