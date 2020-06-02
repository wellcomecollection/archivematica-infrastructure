terraform {
  required_version = ">= 0.12"

  backend "s3" {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-developer"

    bucket = "wellcomedigitisation-infra"
    key    = "terraform/archivematica-infra/users.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "critical_staging" {
  backend = "s3"

  config = {
    role_arn = "arn:aws:iam::299497370133:role/workflow-read_only"

    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/critical_staging.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "critical_prod" {
  backend = "s3"

  config = {
    role_arn = "arn:aws:iam::299497370133:role/workflow-read_only"

    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/critical_prod.tfstate"
    region = "eu-west-1"
  }
}
