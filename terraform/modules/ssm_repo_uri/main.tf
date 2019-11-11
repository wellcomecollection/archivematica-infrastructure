variable "label" {
  default = "prod"
}

variable "image_name" {}

data "aws_ssm_parameter" "release_id" {
  name = "/archivematica/images/${var.label}/${var.image_name}"
}

output "value" {
  value = data.aws_ssm_parameter.release_id.value
}
