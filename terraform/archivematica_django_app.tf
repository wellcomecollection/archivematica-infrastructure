
#https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#LoadBalancers:search=archivematica-elb;sort=loadBalancerName

resource "aws_elb" "archivematica-elb" {
  name = "archivematica-elb"

  listener {
    instance_port = 8000
    instance_protocol = "http"
    lb_port = 8000
    lb_protocol = "http"
  }

  listener {
    instance_port = 8001
    instance_protocol = "http"
    lb_port = 8001
    lb_protocol = "http"
  }

  listener {
    instance_port = 8002
    instance_protocol = "http"
    lb_port = 8002
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 15
    target = "HTTP:8000/"
    interval = 60
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  subnets = [
    "${aws_subnet.archivematica-subnet-public1.id}",
    "${aws_subnet.archivematica-subnet-public2.id}"
  ]
  security_groups = ["${aws_security_group.archivematica-ecs-securitygroup.id}"]

  tags {
    Name = "archivematica-elb"
  }
}

//resource "aws_cloudwatch_log_group" "archivematica-django-app-log-group" {
//  name = "archivematica-django-app-log-group"
//}

resource "aws_ecs_cluster" "archivematica-ecs-cluster" {
  name = "archivematica-ecs-cluster"
}

resource "aws_ecr_repository" "archivematica-ecr-repository" {
  name = "archivematica_django_app"
}

resource "aws_ecr_repository" "archivematica-ecr-dashboard-repository" {
  name = "archivematica_dashboard"
}

variable "archivematica_ebs_host_path" {
  default = "/mnt/ebs"
}

variable "archivematica_ebs_device_name" {
  default = "/dev/xvdb"
}

variable "archivematica_ebs_volume_type" {
  default = "standard"
}

variable "archivematica_ebs_volume_id" {
  default = "/dev/xvdb"
}

variable "archivematica_ebs_volume_size" {
  default = "16"  # GB
}


data "template_file" "archivematica-userdata" {
  template = "${file("ecs_task__django_app_volume_test__user_data.tpl")}"

  vars {
    cluster_name  = "archivematica-ecs-cluster"
    ebs_volume_id = "${var.archivematica_ebs_volume_id}"
    ebs_host_path = "${var.archivematica_ebs_host_path}"
  }
}

resource "aws_launch_configuration" "archivematica-ecs-launchconfig" {
  name_prefix = "archivematica-launchconfig"
  image_id = "ami-0627e141ce928067c" #"ami-066826c6a40879d75"
  instance_type = "${var.ECS_INSTANCE_TYPE}"
  key_name = "${aws_key_pair.archivematica-sshkey.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs-instance-profile.id}"  #"${aws_iam_instance_profile.archivematica-ecs-iam-instance-profile.id}"
  security_groups = ["${aws_security_group.archivematica-ecs-securitygroup.id}"]
  #user_data = "#!/bin/bash \necho 'ECS_CLUSTER=archivematica-ecs-cluster' > /etc/ecs/ecs.config \nstart ecs"
  #user_data = "#!/bin/bash\necho 'ECS_CLUSTER=archivematica-ecs-cluster' > /etc/ecs/ecs.config\nstart ecs"
  #user_data = "${file("aws_launch_configuration_user_data.txt")}"
  user_data   = "${data.template_file.archivematica-userdata.rendered}"
  lifecycle { create_before_destroy = true }

  ebs_block_device {
    volume_size = "${var.archivematica_ebs_volume_size}"
    device_name = "${var.archivematica_ebs_device_name}"
    volume_type = "${var.archivematica_ebs_volume_type}"
    delete_on_termination = "true"
  }
}

resource "aws_autoscaling_group" "archivematica-ecs-autoscaling-group" {
  name = "archivematica-ecs-autoscaling-group"
  vpc_zone_identifier = [
    "${aws_subnet.archivematica-subnet-public1.id}",
    "${aws_subnet.archivematica-subnet-public2.id}"
  ]
  launch_configuration = "${aws_launch_configuration.archivematica-ecs-launchconfig.name}"
  min_size = 1
  max_size = 1

  #health_check_grace_period = 150  # needs to be greater than installation time of services
  #health_check_type = "ELB"
  #load_balancers = ["${aws_elb.my-elb.name}"]
  force_delete = true

  tag {
    key = "Name"
    value = "archivematica-ecs-container"
    propagate_at_launch = true
  }
  # we can also add load balancers (load_balancers for ELBs, target_group_arns for ALBs)
}


resource "aws_ecs_task_definition" "archivematica-django-app-task-definition" {
  container_definitions = "${file("tasks/ecs_task__django_app_volume_test.json")}"
  family = "archivematica-django-app"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  volume {
    name      = "archivematica-ebs-volume"
    host_path = "${var.archivematica_ebs_host_path}"
  }
}

resource "aws_ecs_task_definition" "archivematica-django-app-task-definition3" {
  container_definitions = "${file("tasks/ecs_task__django_app_volume_test3.json")}"
  family = "archivematica-django-app3"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  volume {
    name      = "archivematica-ebs-volume"
    host_path = "${var.archivematica_ebs_host_path}"
  }
}

resource "aws_ecs_task_definition" "archivematica-dashboard" {
  container_definitions = "${file("tasks/archivematica_dashboard.json")}"
  family = "archivematica-dashboard"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  volume {
    name      = "archivematica-ebs-volume"
    host_path = "${var.archivematica_ebs_host_path}"
  }
}


resource "aws_ecs_service" "archivematica-ecs-django-app-service" {
  name = "archivematica-ecs-django-app-service"
  cluster = "${aws_ecs_cluster.archivematica-ecs-cluster.id}"
  #task_definition = "${aws_ecs_task_definition.archivematica-django-app-task-definition.arn}"
  task_definition = "${aws_ecs_task_definition.archivematica-django-app-task-definition.arn}"
  desired_count = 1
  launch_type = "EC2"
  iam_role = "${aws_iam_role.ecs-service-role.arn}" #"${aws_iam_role.archivematica-ecs-service-role.arn}"
  # is this necessary? -> depends_on = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]

  load_balancer {
    elb_name = "${aws_elb.archivematica-elb.name}"
    container_name = "archivematica_django_app"
    container_port = 8000
  }
  lifecycle { ignore_changes = ["task_definition"]}
  # todo: maybe add custom attribute to ec2 instance and reference in placement_constraints here
}

resource "aws_ecs_service" "archivematica-ecs-django-app-service3" {
  name = "archivematica-ecs-django-app-service3"
  cluster = "${aws_ecs_cluster.archivematica-ecs-cluster.id}"
  #task_definition = "${aws_ecs_task_definition.archivematica-django-app-task-definition.arn}"
  task_definition = "${aws_ecs_task_definition.archivematica-django-app-task-definition3.arn}"
  desired_count = 1
  launch_type = "EC2"
  iam_role = "${aws_iam_role.ecs-service-role.arn}" #"${aws_iam_role.archivematica-ecs-service-role.arn}"
  # is this necessary? -> depends_on = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]

  load_balancer {
    elb_name = "${aws_elb.archivematica-elb.name}"
    container_name = "archivematica_django_app3"
    container_port = 8001
  }
  lifecycle { ignore_changes = ["task_definition"]}
}

resource "aws_ecs_service" "archivematica-dashboard" {
  name = "archivematica-dashboard"
  cluster = "${aws_ecs_cluster.archivematica-ecs-cluster.id}"
  #task_definition = "${aws_ecs_task_definition.archivematica-django-app-task-definition.arn}"
  task_definition = "${aws_ecs_task_definition.archivematica-dashboard.arn}"
  desired_count = 1
  launch_type = "EC2"
  iam_role = "${aws_iam_role.ecs-service-role.arn}" #"${aws_iam_role.archivematica-ecs-service-role.arn}"
  # is this necessary? -> depends_on = ["aws_iam_role_policy_attachment.ecs-service-role-attachment"]

  load_balancer {
    elb_name = "${aws_elb.archivematica-elb.name}"
    container_name = "archivematica_dashboard"
    container_port = 8002
  }
  lifecycle { ignore_changes = ["task_definition"]}
}
