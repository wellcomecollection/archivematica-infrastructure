data "terraform_remote_state" "workflow" {
  backend = "s3"

  config {
    role_arn = "arn:aws:iam::299497370133:role/workflow-developer"

    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/workflow.tfstate"
    region = "eu-west-1"
  }
}
