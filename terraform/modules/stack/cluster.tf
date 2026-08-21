module "cluster" {
  source = "./cluster"

  vpc_id          = var.vpc_id
  private_subnets = var.network_private_subnets

  ebs_volume_id = var.ebs_volume_id

  cluster_name = aws_ecs_cluster.archivematica.name

  # We want an instance with enough CPU/memory to run all the tasks *and* have
  # room to add new tasks, and with enough Elastic Network Interfaces to run
  # at least three tasks at once.  The ECS agent grabs one ENI, so we need >=5.
  #
  # See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI
  instance_type = "c5.4xlarge"

  container_host_ami = var.container_host_ami
}
