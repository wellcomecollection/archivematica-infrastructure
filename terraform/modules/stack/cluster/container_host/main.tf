resource "aws_volume_attachment" "ebs" {
  device_name = "/dev/xvdb"
  instance_id = aws_instance.container_host.id
  volume_id   = var.ebs_volume_id
}

resource "aws_instance" "container_host" {
  ami = local.ecs_optimised_ami

  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = module.security_groups.instance_security_groups
  subnet_id              = var.subnets[0]

  user_data = data.template_file.userdata.rendered

  iam_instance_profile = module.instance_profile.name

  tags = {
    Name = "${var.cluster_name}-container_host"
  }
}

module "security_groups" {
  source = "../security_groups"

  name   = var.cluster_name
  vpc_id = var.vpc_id

  controlled_access_cidr_ingress    = var.controlled_access_cidr_ingress
  controlled_access_security_groups = var.ssh_ingress_security_groups
}

module "instance_profile" {
  source = "../instance_profile"
  name   = var.cluster_name
}

data "template_file" "userdata" {
  template = file("${path.module}/ebs.tpl")

  vars = {
    cluster_name  = var.cluster_name
    ebs_volume_id = "/dev/xvdb"
    ebs_host_path = "/ebs"
    region        = var.region
  }
}
