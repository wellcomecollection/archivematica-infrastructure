resource "aws_security_group" "interservice" {
  name        = "archivematica_${var.namespace}_interservice"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}
