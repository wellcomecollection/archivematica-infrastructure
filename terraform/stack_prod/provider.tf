provider "aws" {
  region = var.region

  # Ignore deployment tags on services
  ignore_tags {
    keys = ["deployment:label"]
  }

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-admin"
  }

  default_tags {
    tags = {
      TerraformConfigurationURL = "https://github.com/wellcomecollection/goobi-infrastructure/tree/master/terraform/stack_prod"
      Environment               = "Production"
      Department                = "Digital Production"
      Division                  = "Culture and Society"
      Use                       = "Archivematica"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "digitisation"

  assume_role {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-admin"
  }
}

provider "aws" {
  region = "eu-west-1"
  alias  = "dns"

  assume_role {
    role_arn = "arn:aws:iam::267269328833:role/wellcomecollection-assume_role_hosted_zone_update"
  }
}
