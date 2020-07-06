provider "aws" {
  region  = var.region
  version = "~> 2.69"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-admin"
  }
}

provider "aws" {
  region  = "eu-west-1"
  version = "~> 2.69"
  alias   = "digitisation"

  assume_role {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-admin"
  }
}

provider "aws" {
  region  = "eu-west-1"
  version = "~> 2.69"
  alias   = "dns"

  assume_role {
    role_arn = "arn:aws:iam::267269328833:role/wellcomecollection-assume_role_hosted_zone_update"
  }
}
