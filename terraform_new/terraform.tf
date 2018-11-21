

terraform {
  backend "s3" {
    bucket = "wellcomecollection-platform-infra"
    key    = "terraform/archivematica-infra.tfstate"
    region = "eu-west-1"
  }
}