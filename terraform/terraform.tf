terraform {
  required_version = ">= 0.9"

  backend "s3" {
    bucket   = "wellcomecollection-workflow-infra"
    key      = "terraform/state/archivematica-infra.tfstate"
    region   = "eu-west-1"
    role_arn = "arn:aws:iam::299497370133:role/developer"
  }
}

# data "terraform_remote_state" "workflow" {
#   backend = "s3"
#
#   config {
#     bucket   = "wellcomecollection-workflow-infra"
#     key      = "terraform/workflow.tfstate"
#     region   = "eu-west-1"
#     role_arn = "arn:aws:iam::299497370133:role/developer"
#   }
# }
