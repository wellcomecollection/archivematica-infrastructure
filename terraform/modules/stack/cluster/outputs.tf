output "ec2_instance_arns" {
  value = [module.container_host.arn]
}

output "ec2_instance_ids" {
  value = [module.container_host.id]
}
