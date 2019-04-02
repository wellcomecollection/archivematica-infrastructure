output "task_definition" {
  value = "${data.template_file.definition.rendered}"
}