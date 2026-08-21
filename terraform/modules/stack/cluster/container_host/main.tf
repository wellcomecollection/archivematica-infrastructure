resource "aws_volume_attachment" "ebs" {
  device_name = "/dev/xvdb"
  instance_id = aws_instance.container_host.id
  volume_id   = var.ebs_volume_id
}

resource "aws_instance" "container_host" {
  ami = var.container_host_ami

  instance_type = var.instance_type

  key_name = var.key_name

  vpc_security_group_ids = module.security_groups.instance_security_groups
  subnet_id              = var.subnets[0]

  user_data = templatefile(
    "${path.module}/ebs.tpl",
    {
      cluster_name = var.cluster_name

      ebs_device_path = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_${replace(var.ebs_volume_id, "-", "")}"
      ebs_host_path   = "/ebs"
      ebs_volume_id   = var.ebs_volume_id
    }
  )

  # Updating the bootstrap should stop and start the existing instance so the
  # persistent EBS volume remains attached. Do not replace the instance.
  user_data_replace_on_change = false

  iam_instance_profile = module.instance_profile.name

  tags = {
    Name = "${var.cluster_name}-container_host"
  }
}

module "security_groups" {
  source = "../security_groups"

  name   = var.cluster_name
  vpc_id = var.vpc_id
}

module "instance_profile" {
  source = "../instance_profile"
  name   = var.cluster_name
}
