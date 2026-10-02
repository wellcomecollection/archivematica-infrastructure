# Explore performance in CloudWatch

Open `archivematica-prod` or `archivematica-staging` in the AWS CloudWatch
console in Ireland and select the incident's time range. The dashboard combines
application, host, ECS and shared EBS measurements to investigate slow
processing, memory pressure and task stops. It provides evidence, without alerts
or automatic recovery. Match task IDs and UTC times with [application logs].

## Read the dashboard

### Is collection working?

Check these panels before interpreting an empty processing graph. Missing data
is unknown, not zero; scheduled shutdowns and disabled collection leave gaps.

| Panel                                                      | How to interpret it                                                                                                                                                                                                                                         |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Prometheus scrape availability by task (1 = reachable)** | `1` means a target responded to its scrape; `0` means the scrape failed. A missing task may have stopped or disappeared from discovery, rather than being healthy.                                                                                          |
| **Collection coverage (1 = available; gaps are unknown)**  | Discovery and cgroup collection report `1` when available. This does not confirm CloudWatch accepted the exported metrics; check `/archivematica/ENV/observability` for `Exporting failed` or `Partial success response` when data is unexpectedly missing. |

### Is processing making progress?

Compare unfinished work with new completions, rather than treating an active
count as proof of progress. Rates use rolling five-minute windows; the collector
starts cumulative counters and histograms from an initial baseline, so activity
before that sample is not included after a collector restart.

| Panel                                                               | How to interpret it                                                                                                                                                                                                   |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Active packages and MCPServer jobs**                              | Counts packages actively being processed and unfinished MCPServer jobs. A steady positive count can mean long work or a stall; packages awaiting manual decisions are not active processing.                          |
| **Jobs waiting within active packages**                             | Jobs queued for their next MCPServer step within active packages. Compare a growing queue with completion rates to distinguish accumulating work from normal processing.                                              |
| **Gearman batches awaiting submission / results**                   | Separates batches not yet submitted from batches awaiting results, which may be queued or running. Neither series measures the actual backlog waiting for MCPClient workers.                                          |
| **Packages waiting to start by type**                               | Packages queued before processing starts. Zero does not mean all work is finished, because active packages are excluded.                                                                                              |
| **MCPClient completed jobs/s by ECS task (all exits)**              | New individual job completions show worker activity, including nonzero exits. Zero can mean idle workers, unfinished long work or a stall; the counters reset when the MCPClient parent restarts.                     |
| **Seconds since last MCPClient completion by ECS task (all exits)** | Age of the latest success or nonzero exit within each ECS task, rather than the age of an unfinished job. No completion produces no value, and one busy worker can hide another stalled worker in the same task.      |
| **Completed worker batch duration p95 by script (seconds)**         | Estimated duration below which 95% of completed batches fall, grouped by script. A batch can contain several jobs; unfinished batches are excluded, and gaps are expected when none finish in the five-minute window. |
| **AIPs/DIPs reported stored per hour**                              | Storage completions reported by MCPClient during the rolling last hour. Worker job completions alone do not establish successful storage; correlate this panel with the package status and logs.                      |

### Is Storage Service busy?

| Panel                                          | How to interpret it                                                                                                                                                                                       |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Storage Service HTTP responses/s by status** | Request activity and HTTP status codes help identify API errors. Successful responses do not establish that a long asynchronous operation has finished.                                                   |
| **Storage Service running asynchronous tasks** | Operations running in live worker processes. Worker exit removes its contribution even if an unfinished database record remains, so check the operation's result and logs before concluding it succeeded. |

### Are failures or restarts interrupting work?

| Panel                                       | How to interpret it                                                                                                                                                                                                                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **MCPClient nonzero job exits/s by script** | Highlights scripts returning nonzero exit codes. These can be normal workflow decisions, such as finding no extractable files; use application logs to distinguish them from failures.                                               |
| **Unexpected MCPServer job exceptions/s**   | Unexpected exceptions that stop an MCPServer job. Check MCPServer logs for the package and traceback; these are distinct from normal nonzero worker exits.                                                                           |
| **Running and pending ECS tasks**           | Shows whether service tasks are running or waiting to start. Pending tasks or falling running counts can explain missing worker capacity; normal deployments and scheduled shutdowns also change these counts.                       |
| **Recent stopped tasks**                    | Stop reasons and container exit details help identify OOM failures and crashes. Deployment replacements also appear here; use the saved `archivematica-ENV/deployments-and-service-events` query to correlate them with deployments. |

### Is memory pressure affecting Storage Service?

| Panel                                                              | How to interpret it                                                                                                                                                                                                                             |
| ------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ECS service memory — incomplete cache accounting**               | Service memory utilization provides a broad comparison between services. It excludes some file cache and cannot establish how close Storage Service is to its enforced task limit.                                                              |
| **Host memory by state (bytes)**                                   | Separates host memory states to show pressure across the whole machine. Host free memory does not prevent a task from reaching its own smaller memory limit.                                                                                    |
| **Storage Service task memory / enforced limit (including cache)** | A ratio approaching `1` means memory charged to the task is approaching its enforced limit. Samples can miss brief peaks; confirm OOM failures through stopped-task reasons.                                                                    |
| **Storage Service task memory components (bytes)**                 | Separates anonymous memory, file cache, dirty pages and pages being written back to help explain pressure. Dirty and writeback pages are parts of file memory; task and container accounting also overlap, so do not add these values together. |

Use the saved `archivematica-ENV/cgroup-memory` query for task-level samples,
peaks and OOM counters around the incident.

### Is the host or shared disk a bottleneck?

| Panel                                                      | How to interpret it                                                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Host CPU time/s by state**                               | CPU time consumed each second across the host's cores, separated by state. Values are core-seconds per second, not percentages; a mostly idle host can still have a blocked application.                                                                                                                                         |
| **Host filesystem usage (%)**                              | Percentage of usable space occupied on the host's `/` and `/ebs` filesystems, sampled once a minute; reserved filesystem space is excluded. Near `100` means little space remains, but this does not measure I/O saturation or inode exhaustion.                                                                                 |
| **Shared EBS throughput (MiB/s)**                          | Read and write rates for the shared volume. Throughput alone does not establish a disk bottleneck; compare it with queue length and capacity checks.                                                                                                                                                                             |
| **Shared EBS queue and selected instance capacity checks** | Queue length shows outstanding I/O; a capacity check of `1` reports an exceeded limit. Checks require the incident's host in **EBS instance ID**, while queue length uses only the volume; the saved `ebs-attachment-history` query can help find older hosts, but an `unknown` volume ID needs independent attachment evidence. |

## Enable or disable collection

Read `observability_enabled` in the [staging Terraform settings] or
[production Terraform settings] to find each environment's configured default.
Check `.tfvars`, `TF_VAR_observability_enabled` and `-var` overrides as well.
Edit the setting, then review and apply a full-stack plan; the checked-in value
describes the desired configuration, rather than confirming what is deployed.

`true` starts the collector, enhanced ECS metrics and lifecycle capture; `false`
stops new collection while preserving historical evidence, dashboards and saved
queries. Application logging and standard AWS metrics continue. Evidence from
periods when collection was off cannot be recovered.

Each stack pins the published collector digest in `locals.tf`, alongside other
image versions. See the [collector build and tests] for changing the image;
application task definition changes restart services.

## Cost and retention

Using [Ireland prices as of October 2026], estimate new collection charges for
these example running periods:

| Collection period                         | New collection cost (USD) |
| ----------------------------------------- | ------------------------- |
| Production, continuously for a month      | $85–105                   |
| Staging, weekday office hours for a month | $30–40                    |
| Staging, five weekdays                    | $7–9                      |

These estimates assume about 1,100 enhanced ECS metrics, 10–50 GB of
application/host metrics and 2 GB of logs per 730 running hours. Ingestion
volumes are assumptions; staging examples scale to its 07:00–19:00 UTC weekday
schedule. Check actual ingestion and billing; estimates exclude retained logs,
dashboards, queries, network processing, tax and account discounts. Disabling
collection avoids new collection charges and frees host capacity without
reducing the EC2 bill.

The [OpenTelemetry metric ingestion price] includes 15 months of history, with
no separate metric storage charge. Logs remain chargeable when collection is
disabled: diagnostics and Container Insights logs expire after 90 days, and
lifecycle events after 400 days. To reduce storage costs, shorten
`retention_in_days` for [collector diagnostics], [Container Insights logs] or
[lifecycle events], then review and apply the affected stack plans. These
settings are shared by both environments, and [automatic expiration] permanently
removes older log evidence.

[application logs]: where-to-find-application-logs.md
[automatic expiration]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/Working-with-log-groups-and-streams.html#SettingLogRetention
[collector build and tests]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/archivematica-apps/archivematica-observability/README.md
[collector diagnostics]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/observability/collector.tf
[container insights logs]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/stack/ecs.tf
[ireland prices as of october 2026]: https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonCloudWatch/current/eu-west-1/index.json
[lifecycle events]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/modules/observability/events.tf
[opentelemetry metric ingestion price]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-otel-pricing.html
[production terraform settings]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_prod/observability.tf
[staging terraform settings]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/terraform/stack_staging/observability.tf
