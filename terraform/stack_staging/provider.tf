locals {
  default_tags = {
    TerraformConfigurationURL = "https://github.com/wellcomecollection/archivematica-infrastructure/tree/master/terraform/stack_staging"
    Environment               = "Staging"
    Department                = "Digital Production"
    Division                  = "Culture and Society"
    Use                       = "Archivematica"
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-admin"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "digitisation"

  assume_role {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-admin"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dns"

  assume_role {
    role_arn = "arn:aws:iam::267269328833:role/wellcomecollection-assume_role_hosted_zone_update"
  }

  default_tags {
    tags = local.default_tags
  }
}
