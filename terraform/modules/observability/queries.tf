resource "aws_cloudwatch_query_definition" "memory" {
  name            = "${local.name}/cgroup-memory"
  log_group_names = [aws_cloudwatch_log_group.diagnostics.name]
  query_string    = <<-QUERY
    fields @timestamp, task_id, service, scope, container, current, limit, peak, anon, file, file_dirty, file_writeback, event_max, event_oom, event_oom_kill, limit_hits
    | filter event = "cgroup_memory"
    | sort @timestamp desc
    | limit 1000
  QUERY
}
