terraform {
  required_version = ">= 1.14"

  backend "s3" {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/stack_staging.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
    }
  }
}

data "terraform_remote_state" "critical" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/critical_staging.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-read_only"
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

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/archivematica-infra/infra.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::299497370133:role/workflow-read_only"
    }
  }
}

data "terraform_remote_state" "shared_infra" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-platform-infra"
    key    = "terraform/platform-infrastructure/shared.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::760097843905:role/platform-read_only"
    }
  }
}

data "terraform_remote_state" "monitoring" {
  backend = "s3"

  config = {
    bucket = "wellcomecollection-platform-infra"
    key    = "terraform/monitoring.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::760097843905:role/platform-read_only"
    }
  }
}
