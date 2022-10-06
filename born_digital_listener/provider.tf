provider "aws" {
  assume_role {
    role_arn = "arn:aws:iam::975596993436:role/storage-developer"
  }

  alias  = "storage"
  region = "eu-west-1"

  default_tags {
    tags = local.default_tags
  }
}

locals {
  default_tags = {
    TerraformConfigurationURL = "https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/born_digital_listener"
    Department                = "Digital Platform"
    Division                  = "Wellcome Collection"
    Use                       = "Archivematica"
    Environment               = "Production"
  }
}
