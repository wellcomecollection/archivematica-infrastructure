terraform {
  required_version = ">= 0.11"

  backend "s3" {
    role_arn = "arn:aws:iam::299497370133:role/developer"

    bucket         = "wellcomecollection-workflow-infra"
    key            = "terraform/archivematica/archivematica-infra-builds.tfstate"
    dynamodb_table = "terraform-locktable"
    region         = "eu-west-1"
  }
}
