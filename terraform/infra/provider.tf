provider "aws" {
  region  = var.region
  version = "~> 2.69"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
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
