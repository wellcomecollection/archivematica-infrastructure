output "instance_security_groups" {
  value = [
    aws_security_group.full_egress.id,
    aws_security_group.ssh_controlled_ingress.id,
  ]
}

output "ssh_controlled_ingress" {
  value = [aws_security_group.ssh_controlled_ingress.id]
}
