terraform {
  required_version = ">= 0.9"

  backend "s3" {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/state/archivematica-infra.tfstate"
    region = "eu-west-1"
  }
}
