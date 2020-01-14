data "aws_ssm_parameter" "ecs_optimised_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

locals {
  ecs_optimised_ami = data.aws_ssm_parameter.ecs_optimised_ami.value
}