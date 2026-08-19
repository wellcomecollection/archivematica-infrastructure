module "container_host" {
  source = "./container_host"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id

  ssh_ingress_security_groups = flatten(module.bastion_host[*].ssh_controlled_ingress_sg)

  subnets  = var.private_subnets
  key_name = "wellcomedigitalworkflow"

  region = var.region

  instance_type = var.instance_type

  ebs_volume_id      = var.ebs_volume_id
  container_host_ami = var.container_host_ami
}

# Production still uses the bastion introduced in #149. Staging omits the AMI
# after #172 and therefore has no bastion resources.
module "bastion_host" {
  source = "./bastion_host"
  count  = var.bastion_host_ami == null ? 0 : 1

  vpc_id = var.vpc_id

  name = "${var.name}-bastion"

  controlled_access_cidr_ingress = var.controlled_access_cidr_ingress

  key_name         = var.key_name
  subnet_list      = var.public_subnets
  bastion_host_ami = var.bastion_host_ami
}
