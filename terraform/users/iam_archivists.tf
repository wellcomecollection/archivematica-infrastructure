data "aws_ssm_parameter" "archivists_s3_upload-usernames" {
  name = "archivists_s3_upload-usernames"
}

locals {
  names = concat(
    ["archivists_s3_upload"],
    split(",", nonsensitive(data.aws_ssm_parameter.archivists_s3_upload-usernames.value))
  )
}

resource "aws_iam_user" "user" {
  for_each = toset(local.names)

  name = "archivists_s3_upload-${each.key}"
}

resource "aws_iam_user_policy" "allow_upload" {
  for_each = toset(local.names)

  user   = aws_iam_user.user[each.key].name
  policy = data.aws_iam_policy_document.allow_s3_upload.json
}

resource "aws_iam_user_policy" "allow_download" {
  for_each = toset(local.names)

  user   = aws_iam_user.user[each.key].name
  policy = data.aws_iam_policy_document.allow_s3_download.json
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

data "aws_iam_policy_document" "allow_s3_download" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:List*"
    ]

    resources = [
      "arn:aws:s3:::wellcomecollection-storage",
      "arn:aws:s3:::wellcomecollection-storage/*",
      "arn:aws:s3:::wellcomecollection-storage-staging",
      "arn:aws:s3:::wellcomecollection-storage-staging/*",
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
