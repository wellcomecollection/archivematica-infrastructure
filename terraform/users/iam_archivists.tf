resource "aws_iam_user" "archivists_s3_upload" {
  name = "archivists_s3_upload"

  tags = {
    terraform-stack = "wellcomecollection/archivematica-infra/users"
  }
}

data "aws_iam_policy_document" "allow_s3_upload" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${data.terraform_remote_state.critical_staging.outputs.transfer_source_bucket_arn}/*",
      "${data.terraform_remote_state.critical_prod.outputs.transfer_source_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:List*",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_access_key" "archivists_s3_upload" {
  user = aws_iam_user.archivists_s3_upload.name
}

resource "aws_iam_user_policy" "allow_archivists_s3_upload" {
  user   = aws_iam_user.archivists_s3_upload.name
  policy = data.aws_iam_policy_document.allow_s3_upload.json
}
