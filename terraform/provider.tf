provider "aws" {
  region  = "${var.region}"
  version = "1.54.0"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-admin"
  }
}
