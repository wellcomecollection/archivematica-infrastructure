output "lifecycle_log_group_arn" {
  value = aws_cloudwatch_log_group.lifecycle.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.operations.dashboard_name
}

output "diagnostics_log_group_arn" {
  value = aws_cloudwatch_log_group.diagnostics.arn
}
