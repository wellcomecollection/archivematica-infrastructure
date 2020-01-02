resource "aws_ebs_volume" "ebs" {
  availability_zone = "eu-west-1a"
  size              = 750

  tags = {
    Name = var.asg_name
  }
}

module "cloudformation_stack" {
  source = "../asg"

  subnet_list        = var.subnets
  asg_name           = var.asg_name
  launch_config_name = aws_launch_configuration.launch_config.name

  asg_max     = var.asg_max
  asg_desired = var.asg_desired
  asg_min     = var.asg_min
}

resource "aws_launch_configuration" "launch_config" {
  security_groups = module.security_groups.instance_security_groups

  key_name                    = var.key_name
  image_id                    = var.image_id
  instance_type               = var.instance_type
  iam_instance_profile        = module.instance_profile.name
  user_data                   = data.template_file.userdata.rendered
  associate_public_ip_address = true

  ebs_block_device {
    volume_size = aws_ebs_volume.ebs.size
    device_name = "/dev/xvdb"
    volume_type = "standard"
  }

  lifecycle {
    create_before_destroy = true
  }
}

module "security_groups" {
  source = "../security_groups"

  name   = var.asg_name
  vpc_id = var.vpc_id

  controlled_access_cidr_ingress    = var.controlled_access_cidr_ingress
  controlled_access_security_groups = var.ssh_ingress_security_groups
  custom_security_groups            = var.custom_security_groups
}

module "instance_profile" {
  source = "../instance_profile"
  name   = var.asg_name
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
