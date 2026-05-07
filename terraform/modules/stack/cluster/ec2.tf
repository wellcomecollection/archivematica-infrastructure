module "container_host" {
  source = "./container_host"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id

  subnets  = var.private_subnets
  key_name = "wellcomedigitalworkflow"

  region = var.region

  instance_type = var.instance_type

  ebs_volume_id      = var.ebs_volume_id
  container_host_ami = var.container_host_ami
}
