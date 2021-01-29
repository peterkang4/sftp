###########
# DATA
###########

data "aws_iam_policy_document" "transfer_server_assume_role" {
  statement {
    effect       = "Allow"
    actions      = ["sts:AssumeRole"]

    principals {
      type       = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "transfer_server_assume_policy" {
  statement {
    effect   = "Allow"
    actions  = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      var.S3_BUCKET_ARN,
      var.S3_BUCKET_OBJECT_ARN
    ]
  }
}

data "aws_iam_policy_document" "transfer_server_to_cloudwatch_assume_policy" {
  statement {
    effect    = "Allow"

    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

###########
# RESOURCES
###########

resource "aws_iam_role" "transfer_server_role" {
  name               = "${var.TRANSFER_SERVER_NAME}-transfer_server_role"
  assume_role_policy = data.aws_iam_policy_document.transfer_server_assume_role.json
  tags               = {
    Project          = "peter-sftp-tf"
  }
}

resource "aws_iam_role_policy" "transfer_server_policy" {
  name   = "${var.TRANSFER_SERVER_NAME}-transfer_server_policy"
  role   = aws_iam_role.transfer_server_role.name
  policy = data.aws_iam_policy_document.transfer_server_assume_policy.json
}

resource "aws_iam_role_policy" "transfer_server_to_cloudwatch_policy" {
  name   = "${var.TRANSFER_SERVER_NAME}-transfer_server_to_cloudwatch_policy"
  role   = aws_iam_role.transfer_server_role.name
  policy = data.aws_iam_policy_document.transfer_server_to_cloudwatch_assume_policy.json
}