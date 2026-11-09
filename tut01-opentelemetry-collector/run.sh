#!/usr/bin/env bash
# Reproduces every step of the OpenTelemetry Collector tutorial, in order.
# Tested 2026-11-09: Collector contrib 0.164.0, Jaeger 2.22.0, telemetrygen v0.164.0, Docker 29.
#   ./run.sh step1   start the Collector with the minimal config
#   ./run.sh send    send one trace (3 with N=3)
#   ./run.sh step3 | step4_mistake | step5 | step6_load   switch config and restart
#   ./run.sh load    the load test against the low memory limit (use with step6_load)
#   ./run.sh jaeger  list the services Jaeger has received
#   ./run.sh metrics the Collector's own metrics (step6_load exposes them)
set -euo pipefail
cd "$(dirname "$0")"
GEN=ghcr.io/open-telemetry/opentelemetry-collector-contrib/telemetrygen:v0.164.0
case "${1:-}" in
  step*)  CONFIG="$1" docker compose up -d --force-recreate; sleep 4; docker compose logs otel-collector | tail -5 ;;
  send)   docker run --rm --network lab_default "$GEN" traces --otlp-insecure --otlp-endpoint otel-collector:4317 --traces "${N:-1}" --service "${SERVICE:-checkout}"; sleep 6
          docker compose logs otel-collector | grep -E '"spans"' | tail -2 ;;
  load)   docker run --rm --network lab_default "$GEN" traces --otlp-insecure --otlp-endpoint otel-collector:4317 --rate 0 --workers 16 --duration 20s --child-spans 20 --service load
          docker compose logs otel-collector | grep -E "Refusing data" | tail -3 ;;
  jaeger) docker run --rm --network lab_default curlimages/curl:8.11.1 -s http://jaeger:16686/api/v3/services; echo ;;
  metrics) docker run --rm --network lab_default curlimages/curl:8.11.1 -s http://otel-collector:8888/metrics | grep -E "^otelcol_(receiver_(accepted|refused)_spans|processor_batch_batch_send_size_(sum|count)|exporter_sent_spans)" ;;
  down)   docker compose down ;;
  *) sed -n '2,11p' "$0" ;;
esac
