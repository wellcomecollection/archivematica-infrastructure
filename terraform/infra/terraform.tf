terraform {
  required_version = ">= 1.6"

  backend "s3" {
    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
    }

    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/infra.tfstate"
    region = "eu-west-1"
  }
}
