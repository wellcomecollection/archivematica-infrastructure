locals {
  environment_selector = "\"@resource.deployment.environment.name\"=\"${var.environment}\""
  application_charts = [
    {
      title   = "Host CPU time/s by state"
      queries = ["sum by (state) (rate({\"system.cpu.time\",${local.environment_selector}}[5m]))"]
    },
    {
      title   = "Host memory by state (bytes)"
      queries = ["{\"system.memory.usage\",${local.environment_selector}}"]
    },
    {
      title   = "Host filesystem usage (%)"
      queries = ["100 * {\"system.filesystem.utilization\",${local.environment_selector},mountpoint=~\"/|/ebs\"}"]
    },
    {
      title   = "Storage Service HTTP responses/s by status"
      queries = ["sum by (status) (rate(django_http_responses_total_by_status_total{${local.environment_selector},service=\"am-${var.environment}-storage-service\"}[5m]))"]
    },
    {
      title   = "Storage Service running asynchronous tasks"
      queries = ["async_manager_running_tasks{${local.environment_selector}}"]
    },
    {
      title   = "MCPClient completed jobs/s by ECS task (all exits)"
      queries = ["sum by (task_id) (rate(mcpclient_job_total{${local.environment_selector}}[5m]))"]
    },
    {
      title   = "MCPClient nonzero job exits/s by script"
      queries = ["sum by (script_name) (rate(mcpclient_job_error_total{${local.environment_selector}}[5m]))"]
    },
    {
      title = "Seconds since last MCPClient completion by ECS task (all exits)"
      # CloudWatch requires exact metric names. Include the name in OR matching
      # so a success sample cannot hide a newer error with the same task labels.
      queries = ["time() - (max by (task_id) (mcpclient_job_success_timestamp{${local.environment_selector}} or on (__name__) mcpclient_job_error_timestamp{${local.environment_selector}}) > 0)"]
    },
    {
      title   = "Unexpected MCPServer job exceptions/s"
      queries = ["sum by (task_id) (rate(mcpserver_job_exception_total{${local.environment_selector}}[5m]))"]
    },
    {
      title = "Active packages and MCPServer jobs"
      queries = [
        "mcpserver_active_packages{${local.environment_selector}}",
        "mcpserver_active_jobs{${local.environment_selector}}"
      ]
    },
    {
      title   = "Jobs waiting within active packages"
      queries = ["mcpserver_active_package_job_queue_length{${local.environment_selector}}"]
    },
    {
      title = "Gearman batches awaiting submission / results"
      queries = [
        "mcpserver_gearman_pending_jobs{${local.environment_selector}}",
        "mcpserver_gearman_active_jobs{${local.environment_selector}}"
      ]
    },
    {
      title   = "Packages waiting to start by type"
      queries = ["mcpserver_package_queue_length{${local.environment_selector}}"]
    },
    {
      title   = "Completed worker batch duration p95 by script (seconds)"
      queries = ["histogram_quantile(0.95, sum by (script_name) (rate(mcpclient_task_execution_time_seconds{${local.environment_selector}}[5m])))"]
    },
    {
      title = "AIPs/DIPs reported stored per hour"
      queries = [
        "sum(increase(mcpclient_aips_stored_total{${local.environment_selector}}[1h]))",
        "sum(increase(mcpclient_dips_stored_total{${local.environment_selector}}[1h]))"
      ]
    },
    {
      title   = "Storage Service task memory / enforced limit (including cache)"
      queries = ["archivematica_cgroup_current_bytes{${local.environment_selector},service=\"am-${var.environment}-storage-service\",scope=\"task\"} / archivematica_cgroup_limit_bytes{${local.environment_selector},service=\"am-${var.environment}-storage-service\",scope=\"task\"}"]
    },
    {
      title   = "Storage Service task memory components (bytes)"
      queries = [for component in ["anon", "file", "file_dirty", "file_writeback"] : "archivematica_cgroup_${component}_bytes{${local.environment_selector},service=\"am-${var.environment}-storage-service\",scope=\"task\"}"]
    },
    {
      title   = "Prometheus scrape availability by task (1 = reachable)"
      queries = ["up{${local.environment_selector}}"]
    },
    {
      title = "Collection coverage (1 = available; gaps are unknown)"
      queries = [
        "archivematica_discovery_healthy{${local.environment_selector}}",
        "archivematica_cgroup_collection_healthy{${local.environment_selector}}"
      ]
    }
  ]
  application_widgets = [for index, chart in local.application_charts : {
    type = "chart", x = (index % 2) * 12, y = 26 + floor(index / 2) * 6, width = 12, height = 6
    properties = {
      title = chart.title, region = var.region, view = "line"
      data = { queries = [for n, query in chart.queries : {
        id = "q${n + 1}", type = "cloudwatch-metrics", language = "PromQL", query = query, step = 60
      }] }
    }
  }]
}
