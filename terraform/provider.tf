provider "aws" {
  region  = "${var.region}"
  version = "1.54.0"

  assume_role {
    role_arn     = "arn:aws:iam::299497370133:role/developer"
    session_name = "developer-terraform"
    external_id  = "developer-terraform"
  }
}
