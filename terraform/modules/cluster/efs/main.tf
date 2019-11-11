module "cloudformation_stack" {
  source = "../asg"

  subnet_list        = "${var.subnets}"
  asg_name           = "${var.asg_name}"
  launch_config_name = aws_launch_configuration.launch_config.name

  asg_max     = "${var.asg_max}"
  asg_desired = "${var.asg_desired}"
  asg_min     = "${var.asg_min}"
}

resource "aws_launch_configuration" "launch_config" {
  security_groups = module.security_groups.instance_security_groups

  key_name                    = "${var.key_name}"
  image_id                    = "${var.image_id}"
  instance_type               = "${var.instance_type}"
  iam_instance_profile        = module.instance_profile.name
  user_data                   = data.template_file.userdata.rendered
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

module "security_groups" {
  source = "../security_groups"

  name   = "${var.asg_name}"
  vpc_id = "${var.vpc_id}"

  controlled_access_cidr_ingress    = "${var.controlled_access_cidr_ingress}"
  controlled_access_security_groups = ["${var.ssh_ingress_security_groups}"]
  custom_security_groups            = "${var.custom_security_groups}"
}

module "instance_profile" {
  source = "../instance_profile"
  name   = "${var.asg_name}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/efs.tpl")}"

  vars = {
    cluster_name  = "${var.cluster_name}"
    efs_fs_id     = "${var.efs_fs_id}"
    efs_host_path = "${var.efs_host_path}"
    region        = "${var.region}"
  }
}

module "instance_policy" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/ec2/modules/instance_role_policy?ref=v11.3.1"

  cluster_name               = "${var.cluster_name}"
  instance_profile_role_name = "${module.instance_profile.role_name}"
}
