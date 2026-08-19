terraform {
  # State moves require Terraform 1.1 or later.
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source = "hashicorp/aws"

      configuration_aliases = [aws.digitisation]
    }
  }
}
