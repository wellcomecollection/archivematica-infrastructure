module "container_host" {
  source = "./container_host"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id

  ssh_ingress_security_groups = module.bastion_host.ssh_controlled_ingress_sg

  subnets  = var.private_subnets
  key_name = "wellcomedigitalworkflow"

  region = var.region

  instance_type = var.instance_type

  ebs_volume_id      = var.ebs_volume_id
  container_host_ami = var.container_host_ami
}

module "bastion_host" {
  source = "./bastion_host"

  vpc_id = var.vpc_id

  name = "${var.name}-bastion"

  controlled_access_cidr_ingress = var.controlled_access_cidr_ingress

  key_name         = var.key_name
  subnet_list      = var.public_subnets
  bastion_host_ami = var.bastion_host_ami

}
