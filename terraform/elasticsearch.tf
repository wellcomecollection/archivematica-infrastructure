resource "aws_elasticsearch_domain" "archivematica" {
  domain_name = "archivematica"

  # This is the only version that Archivematica supports.  If/when it gets
  # upgraded to support newer versions, we should replace this with hosted
  # Elastic Cloud.
  elasticsearch_version = "1.5"

  cluster_config {
    instance_type = "r4.large.elasticsearch"
  }

  vpc_options {
    security_group_ids = ["${local.interservice_security_group_id}"]
    subnet_ids         = ["${local.network_private_subnets[0]}"]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }
}

# https://github.com/terraform-providers/terraform-provider-aws/issues/5218
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}
