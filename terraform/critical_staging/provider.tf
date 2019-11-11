provider "aws" {
  region  = var.region
  version = "2.35.0"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
  }
}
