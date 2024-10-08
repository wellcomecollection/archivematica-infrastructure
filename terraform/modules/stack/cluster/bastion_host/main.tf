module "cloudformation_stack" {
  source = "./asg"

  asg_name = var.name

  asg_max     = 2
  asg_desired = 1
  asg_min     = 1

  subnet_list        = var.subnet_list
  launch_config_name = aws_launch_configuration.launch_config.name
}

resource "aws_launch_configuration" "launch_config" {
  security_groups = module.security_groups.instance_security_groups

  key_name                    = var.key_name
  image_id                    = var.bastion_host_ami
  instance_type               = var.instance_type
  iam_instance_profile        = module.instance_profile.name
  user_data                   = var.user_data
  associate_public_ip_address = var.associate_public_ip_address

  lifecycle {
    create_before_destroy = true
  }
}

module "security_groups" {
  source = "../security_groups"

  name   = var.name
  vpc_id = var.vpc_id

  custom_security_groups            = var.custom_security_groups
  controlled_access_cidr_ingress    = var.controlled_access_cidr_ingress
  controlled_access_security_groups = []
}

module "instance_profile" {
  source = "../instance_profile"

  name = var.name
}
