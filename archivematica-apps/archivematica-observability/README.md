# Archivematica observability collector

The collector discovers ECS application tasks, scrapes Prometheus metrics and
sends them to CloudWatch through OpenTelemetry, alongside host and cgroup
measurements. It uses Python 3.15 and builds locked dependencies with uv. The
runtime contains neither uv nor pip and starts Python directly. See the
[operator guide] for interpreting the dashboard and controlling collection
costs.

## Build and test

From the repository root, build the runtime image and run the Docker integration
tests:

```sh
bash .buildkite/scripts/build_docker_image.sh archivematica-observability
bash .buildkite/scripts/run_observability_tests.sh
```

The test script accepts an optional image tag as its first argument to name the
test image.

The script first runs the module's mocked Terraform lifecycle tests with its
pinned Terraform container. Initialization downloads the AWS provider into a
temporary module copy; the tests then run without network access or AWS
credentials. They check collection switches, retained history and host
replacement before the collector integration tests run.

The tests render the Terraform collector configuration with example
infrastructure identifiers and send real compressed OTLP requests to a local
HTTP destination. They check the 1,000-datapoint request limit, cumulative start
timestamps, counter resets, histogram encoding, separate worker identities and
removal of empty records and environment-variable metrics. The test containers
run without external network access or AWS credentials; live verification is
still needed to confirm CloudWatch ingestion and dashboard queries.

Without Docker, run the collector checks with:

```sh
uv run --directory archivematica-apps/archivematica-observability --locked pytest
```

The OTLP integration tests skip without `--otel-config`; the Docker script
supplies this and the OpenTelemetry binary. Buildkite runs the Docker tests
before publishing the image; update the collector digest in staging's
`locals.tf`, then promote the verified digest to production.

[operator guide]: ../../docs/debugging-archivematica/monitoring.md
