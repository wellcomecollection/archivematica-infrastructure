output "instance_security_groups" {
  value = [
    aws_security_group.full_egress.id,
  ]
}
