output "ssh_controlled_ingress_sg" {
  value = module.security_groups.ssh_controlled_ingress
}

output "efs_host_path" {
  value = var.efs_host_path
}
