module "gearman_service" {
  source = "./gearman_service"

  namespace = var.namespace

  container_image = "artefactual/gearmand:1.1.17-alpine"

  command = [
    "--queue-type=redis",
    "--redis-server=${var.redis_server}",
    "--redis-port=${var.redis_port}",
  ]

  cluster_arn  = aws_ecs_cluster.archivematica.id
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}
