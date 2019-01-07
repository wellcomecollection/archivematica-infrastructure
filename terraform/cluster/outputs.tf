output "ssh_controlled_ingress_sg" {
  value = "${module.cluster_hosts.ssh_controlled_ingress_sg}"
}

output "efs_host_path" {
  value = "${module.cluster_hosts.efs_host_path}"
}
