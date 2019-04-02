data "template_file" "definition" {
  template = "${file("${path.module}/task_definition.json.template")}"

  vars {
    log_group_region = "eu-west-1"
    log_group_prefix = ""

    fits_cpu             = "${var.fits_cpu}"
    fits_memory          = "${var.fits_memory}"
    fits_container_image = "${var.fits_container_image}"
    fits_log_group_name  = "fits"
    fits_mount_points    = "${jsonencode(var.fits_mount_points)}"
  }
}
