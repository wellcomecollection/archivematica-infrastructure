data "terraform_remote_state" "workflow" {
  backend = "s3"

  config {
    bucket = "wellcomecollection-workflow-infra"
    key    = "terraform/workflow.tfstate"
    region = "eu-west-1"
  }
}
