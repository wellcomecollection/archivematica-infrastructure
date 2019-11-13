provider "aws" {
  region  = var.region
  version = "2.35.0"

  assume_role {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"
  }
}

provider "aws" {
  region  = "eu-west-1"
	version = "2.35.0"
	alias 	= "routermaster"

	assume_role {
		role_arn = "arn:aws:iam::250790015188:role/wellcomecollection-assume_role_hosted_zone_update"
	}
}
