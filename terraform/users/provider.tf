provider "aws" {
  region  = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-admin"
  }

  default_tags {
    tags = {
      TerraformConfigurationURL = "https://github.com/wellcomecollection/archivematica-infrastructure/tree/master/terraform/users"
      Environment               = "Staging"
      Department                = "Digital Production"
      Division                  = "Culture and Society"
      Use                       = "Archivematica"
    }
  }
}
