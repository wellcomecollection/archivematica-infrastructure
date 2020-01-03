provider "aws" {
  region  = var.region
  version = "2.43.0"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
  }
}

provider "aws" {
  region  = "eu-west-1"
  version = "2.43.0"
  alias   = "digitisation"

  assume_role {
    role_arn = "arn:aws:iam::404315009621:role/digitisation-admin"
  }
}
