output "ssh_controlled_ingress_sg" {
  value = "${module.cluster_hosts.ssh_controlled_ingress_sg}"
}

output "ebs_host_path" {
  value = "${module.cluster_hosts.ebs_host_path}"
}

output "efs_host_path" {
  value = "${module.cluster_hosts.efs_host_path}"
}
