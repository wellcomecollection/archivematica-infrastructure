output "id" {
  value = aws_alb.load_balancer.id
}

output "https_listener_arn" {
  value = aws_alb_listener.https.arn
}

output "dns_name" {
  value = aws_alb.load_balancer.dns_name
}
