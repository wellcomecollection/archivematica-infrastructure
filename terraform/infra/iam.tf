# We need this in the account so we can enable ENI trunking.
# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html
resource "aws_iam_service_linked_role" "ecs" {
  description      = "Role to enable Amazon ECS to manage your cluster."
  aws_service_name = "ecs.amazonaws.com"
}
