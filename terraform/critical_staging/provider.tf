provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-admin"
  }

  default_tags {
    tags = {
      TerraformConfigurationURL = "https://github.com/wellcomecollection/goobi-infrastructure/tree/master/terraform/critical_staging"
      Environment               = "Staging"
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
