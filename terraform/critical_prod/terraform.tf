terraform {
  required_version = ">= 1.14"

  backend "s3" {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/critical_prod.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
    }
  }
}

data "terraform_remote_state" "workflow" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/workflow.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-read_only"
    }
  }
}

data "terraform_remote_state" "storage_service_prod" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-storage-infra"
    key    = "terraform/storage-service/stack_prod.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::975596993436:role/storage-read_only"
    }
  }
}
