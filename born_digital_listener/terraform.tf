terraform {
  backend "s3" {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"

    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/born_digital_listener.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "storage_prod" {
  backend = "s3"

  config = {
    role_arn = "arn:aws:iam::975596993436:role/storage-read_only"
    bucket   = "wellcomecollection-storage-infra"
    key      = "terraform/storage-service/stack_prod.tfstate"
    region   = "eu-west-1"
  }
}

data "terraform_remote_state" "storage_staging" {
  backend = "s3"

  config = {
    role_arn = "arn:aws:iam::975596993436:role/storage-read_only"
    bucket   = "wellcomecollection-storage-infra"
    key      = "terraform/storage-service/stack_staging.tfstate"
    region   = "eu-west-1"
  }
}
