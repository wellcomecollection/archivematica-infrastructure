terraform {
  required_version = ">= 0.9"

  backend "s3" {
    bucket = "wellcomecollection-platform-infra"
    key    = "terraform/archivematica-infra.tfstate"
    region = "eu-west-1"
  }
}
