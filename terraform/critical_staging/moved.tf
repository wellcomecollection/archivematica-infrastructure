# Staging upgraded these resources in place before the shared RDS module became
# their canonical Terraform address. Keep these moves so a state that predates
# that refactor adopts the existing MySQL 8 resources instead of replacing them.
moved {
  from = module.critical.aws_rds_cluster.archivematica
  to   = module.critical.module.aurora_rds_cluster.aws_rds_cluster.cluster
}

# The shared RDS module chains this legacy address to its final `instance`
# address, preserving the same object across both renames.
moved {
  from = module.critical.aws_rds_cluster_instance.archivematica[0]
  to   = module.critical.module.aurora_rds_cluster.aws_rds_cluster_instance.migration_instance
}
