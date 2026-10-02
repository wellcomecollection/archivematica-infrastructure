# Explore performance in CloudWatch

Open the `archivematica-prod` or `archivematica-staging` dashboard in the AWS
CloudWatch console in Ireland.

Use it to investigate queues, worker throughput, processing times, memory
pressure and stopped tasks. It collects diagnostic evidence; it does not send
alerts or recover services automatically.

## Read the evidence

The dashboard combines application metrics with host, ECS and shared EBS
measurements. Saved Logs Insights queries show task stops, deployments and
memory samples. Match task IDs and UTC times with [application logs].

Keep these limits in mind:

- Missing data is unknown, not zero. Check collection coverage and
  `/archivematica/ENV/observability` logs. Staging's scheduled shutdown creates
  gaps.
- For Storage Service memory pressure, compare the **task** cgroup's `current`
  and `limit`. ECS service memory excludes some cache; task and container values
  overlap, so do not add them together.
- Memory samples can miss brief peaks. Use ECS stopped-task reasons when
  investigating an out-of-memory failure.
- Completed-job counters include failures. They survive worker recycling but
  reset when the MCPClient parent restarts. Read them alongside errors; outcome
  counters do not prove packages were successfully stored.
- The collector uses the first sample of each cumulative counter or histogram as
  a baseline, then exports subsequent activity. Rate graphs need multiple
  samples, and activity before that baseline is not included after the collector
  restarts.
- Collector health does not establish that CloudWatch accepted its exports.
  Check `/archivematica/ENV/observability` for `Exporting failed` or
  `Partial success response` when charts have unexpected gaps.

## Enable or disable collection

`observability_enabled` controls whether new monitoring evidence is collected.
To find each environment's configured default, read the `default` value of this
variable in the [staging Terraform settings] or the
[production Terraform settings]. Check any `.tfvars`,
`TF_VAR_observability_enabled` or `-var` overrides as well; these take
precedence over the default. The settings describe the desired configuration,
which takes effect after a Terraform apply.

Set the switch to `true` to collect evidence or `false` to stop new collection
and reduce monitoring costs when evidence is not needed. Measurements from
periods when collection was off cannot be recovered.

The collector image is pinned in each stack's `locals.tf`, alongside the other
deployed image versions. `ecr_repo_urls.observability` reads the repository URL
from shared infrastructure state, and `ecr_image_digests.observability` selects
the published image by its immutable digest. Plans use this pin automatically.
To upgrade the collector, publish the image with Buildkite and update the digest
in staging, then promote the tested digest to production.

To change collection, edit the corresponding Terraform setting, then review and
apply a full-stack plan.

Disabling removes the collector and stops enhanced ECS metrics and lifecycle
collection. Historical evidence, the dashboard and saved queries remain.
Monitoring logs expire after 90 days; lifecycle events after 400 days.
Application logging and standard AWS metrics continue.

## Cost

Using [Ireland prices as of October 2026], budget approximately for periods with
collection enabled:

| Collection period                         | New collection cost (USD) |
| ----------------------------------------- | ------------------------- |
| Production, continuously for a month      | $85–105                   |
| Staging, weekday office hours for a month | $30–40                    |
| Staging, five weekdays                    | $7–9                      |

These examples assume about 1,100 enhanced ECS metrics, plus 10–50 GB of
application/host metrics and 2 GB of logs per 730 running hours. Ingestion
volumes are assumptions, not measurements. Staging estimates scale to its
07:00–19:00 UTC weekday schedule; metrics published outside those hours add
cost.

Disabling collection avoids new collection charges. It frees host capacity
without reducing the EC2 bill. Retained logs, dashboards, queries and network
processing can still cost money. Estimates exclude these charges, tax and
account discounts. Check actual ingestion and billing after the first
investigation.

The collector's [OpenTelemetry metric ingestion price] includes 15 months of
history, with no separate metric storage charge. Log storage remains chargeable
when collection is disabled. To reduce log storage costs, shorten
`retention_in_days` for [collector diagnostics], [Container Insights logs] or
[lifecycle events], then review and apply the affected stack plans. These
settings are shared by both environments; [automatic expiration] permanently
removes older log events and stops their storage charges once they are marked
for deletion.

## Verify configuration changes

Review the full-stack plan before applying. Application task definition changes
restart services. Ensure the pinned collector image is published, and import any
existing monitoring log groups that Terraform does not yet manage; review
retention to avoid expiring older evidence.

With collection enabled, verify ingestion, memory samples and task-stop history
in the environment being changed. Public `/metrics` requests should return 404.

Run `bash .buildkite/scripts/run_observability_tests.sh` from the repository
root to test the rendered collector configuration locally with Docker. The
integration tests send real compressed OTLP requests to a local HTTP destination
that checks the 1,000-datapoint request limit, cumulative start timestamps and
omission of empty metric records. They also check counter increments and resets,
separate worker identities, histogram encoding and filtering of
environment-variable metrics. The test containers have no external network
access or AWS credentials; the rendered configuration uses example
infrastructure identifiers. These tests cover the observed ingestion failures,
but staging verification is still required to confirm CloudWatch accepts the
exports and the dashboard queries return data.

[application logs]: where-to-find-application-logs.md
[automatic expiration]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html#SettingLogRetention
[collector diagnostics]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/observability/collector.tf
[container insights logs]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/stack/ecs.tf
[ireland prices as of october 2026]: https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonCloudWatch/current/eu-west-1/index.json
[lifecycle events]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/observability/events.tf
[opentelemetry metric ingestion price]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-otel-pricing.html
[production terraform settings]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_prod/observability.tf
[staging terraform settings]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_staging/observability.tf
