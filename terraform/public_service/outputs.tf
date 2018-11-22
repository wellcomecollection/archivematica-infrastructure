output "target_group_arn" {
  value = "${data.aws_alb_target_group.tg.arn}"
}

data "aws_alb_target_group" "tg" {
  name = "${module.service.target_group_name}"
}
