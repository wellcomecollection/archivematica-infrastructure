output "ssh_controlled_ingress_sg" {
  value = module.security_groups.ssh_controlled_ingress
}


output "id" {
  value = aws_instance.container_host.id
}

output "arn" {
  value = aws_instance.container_host.arn
}
