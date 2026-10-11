locals {
  otel_config = {
    extensions = {
      sigv4auth    = { region = var.region, service = "monitoring" }
      health_check = { endpoint = "127.0.0.1:13133" }
    }
    receivers = {
      prometheus = {
        config = {
          scrape_configs = [{
            job_name        = "archivematica", scrape_interval = "60s", scrape_timeout = "10s"
            http_sd_configs = [{ url = "http://127.0.0.1:9401/targets", refresh_interval = "60s" }]
            # Filter at ingestion. In particular never export environment_variables_info.
            metric_relabel_configs = [{
              source_labels = ["__name__"], action = "keep"
              regex         = "mcpserver_(gearman_.*|job_exception_total|task_.*|active_.*|package_queue_length)|mcpclient_(job_.*|task_execution_time_seconds.*|transfer_.*|sip_.*|aips_stored.*|dips_stored.*|aip_processing_seconds.*|dip_processing_seconds.*|aip_size_bytes.*|dip_size_bytes.*|aip_files_stored.*|dip_files_stored.*|metric_event.*)|common_ss_api_request_duration_seconds.*|django_http_.*|async_manager_.*"
            }]
            }, {
            job_name       = "cgroups", scrape_interval = "10s"
            static_configs = [{ targets = ["127.0.0.1:9401"] }]
          }]
        }
      }
      hostmetrics = {
        root_path = "/hostfs", collection_interval = "60s"
        scrapers = {
          cpu        = {}, memory = {}, disk = {}, load = {}, paging = {}
          filesystem = { include_mount_points = { mount_points = ["/ebs"], match_type = "strict" } }
        }
      }
    }
    processors = {
      memory_limiter = { check_interval = "1s", limit_mib = 256, spike_limit_mib = 64 }
      # CloudWatch requires start timestamps for cumulative Prometheus metrics.
      # Establish a baseline before exporting increments, avoiding an artificial
      # rate spike when the collector first sees an existing counter.
      metric_start_time = { strategy = "subtract_initial_point" }
      # The baseline leaves empty metric records on their first scrape, which
      # CloudWatch rejects even though they contain no datapoints.
      "filter/empty_metrics" = {
        error_mode        = "ignore"
        metric_conditions = ["Len(metric.data_points) == 0"]
      }
      resource = { attributes = [
        { key = "deployment.environment.name", value = var.environment, action = "upsert" },
        { key = "service.name", value = "archivematica-observability", action = "upsert" },
        { key = "aws.ecs.cluster.arn", value = var.cluster_arn, action = "upsert" }
      ] }
      # CloudWatch rejects an entire OTLP request above 1,000 datapoints.
      batch = { timeout = "10s", send_batch_size = 1000, send_batch_max_size = 1000 }
    }
    exporters = {
      otlphttp = {
        metrics_endpoint = "https://monitoring.${var.region}.amazonaws.com/v1/metrics"
        auth             = { authenticator = "sigv4auth" }
        compression      = "gzip"
        retry_on_failure = { enabled = true, initial_interval = "1s", max_interval = "30s", max_elapsed_time = "300s" }
        sending_queue    = { enabled = true, queue_size = 100 }
      }
    }
    service = {
      extensions = ["sigv4auth", "health_check"]
      telemetry = { metrics = { readers = [{ pull = { exporter = { prometheus = {
        host = "127.0.0.1", port = 8888
      } } } }] } }
      pipelines = { metrics = {
        receivers  = ["prometheus", "hostmetrics"]
        processors = ["memory_limiter", "resource", "metric_start_time", "filter/empty_metrics", "batch"]
        exporters  = ["otlphttp"]
      } }
    }
  }
}
