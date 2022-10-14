resource "aws_cloudformation_stack" "ecs_asg" {
  name = var.asg_name

  template_body = templatefile(
    "${path.module}/asg.json.tpl",
    {
      launch_config_name  = var.launch_config_name
      vpc_zone_identifier = jsonencode(var.subnet_list)
      asg_min_size        = var.asg_min
      asg_desired_size    = var.asg_desired
      asg_max_size        = var.asg_max
      asg_name            = var.asg_name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
