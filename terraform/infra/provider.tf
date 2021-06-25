provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
  }

  default_tags {
    tags = {
      TerraformConfigurationURL = "https://github.com/wellcomecollection/goobi-infrastructure/tree/master/terraform/infra"
      Environment               = "Production"
      Department                = "Digital Production"
      Division                  = "Culture and Society"
      Use                       = "Archivematica"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dns"

  assume_role {
    role_arn = "arn:aws:iam::267269328833:role/wellcomecollection-assume_role_hosted_zone_update"
  }
}
