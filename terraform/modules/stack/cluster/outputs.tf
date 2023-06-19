output "ssh_controlled_ingress_sg" {
  value = module.container_host.ssh_controlled_ingress_sg
}

output "ec2_instance_arns" {
  value = [
    module.container_host.arn,
  ]
}