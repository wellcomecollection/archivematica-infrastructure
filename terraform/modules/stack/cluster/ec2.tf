module "container_host" {
  source = "./container_host"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id

  subnets = var.private_subnets

  # key_name is a ForceNew attribute of aws_instance. Retain this legacy
  # setting so removing the bastion does not also replace the ECS host. Remove
  # it during the next planned host replacement, after confirming that the new
  # host is managed and reachable through SSM.
  key_name = "wellcomedigitalworkflow"

  instance_type = var.instance_type

  ebs_volume_id      = var.ebs_volume_id
  container_host_ami = var.container_host_ami
}
