# module "network" {
#   source     = "git::https://github.com/wellcometrust/terraform.git//network?ref=workaround_count_computed"
#   name       = "archivematica"
#   cidr_block = "10.51.0.0/16"
#   az_count   = 3
# }
#
# resource "aws_security_group" "service_egress" {
#   name   = "archivematica_service_egress_security_group"
#   vpc_id = "${module.network.vpc_id}"
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags {
#     Name = "archivematica-egress"
#   }
# }
#
# resource "aws_security_group" "interservice" {
#   name   = "archivematica_interservice_security_group"
#   vpc_id = "${module.network.vpc_id}"
#
#   ingress {
#     from_port = 0
#     to_port   = 0
#     protocol  = "-1"
#     self      = true
#   }
#
#   tags {
#     Name = "archivematica-interservice"
#   }
# }
#
# resource "aws_security_group" "service_lb" {
#   name   = "workflow_service_lb_security_group"
#   vpc_id = "${module.network.vpc_id}"
#
#   ingress {
#     protocol  = "tcp"
#     from_port = 0
#     to_port   = 65535
#     self      = true
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags {
#     Name = "archivematica-service-lb"
#   }
# }
#
# module "load_balancer" {
#   source = "load_balancer"
#
#   name = "archivematica"
#
#   vpc_id         = "${module.network.vpc_id}"
#   public_subnets = "${module.network.public_subnets}"
#
#   certificate_domain = "archivematica.wellcomecollection.org"
#
#   service_lb_security_group_ids = [
#     "${aws_security_group.service_lb.id}",
#   ]
#
#   lb_controlled_ingress_cidrs = ["${var.admin_cidr_ingress}"]
# }
#