# IAM
data "aws_iam_policy_document" "transfer_server_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "transfer_server_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
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
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

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

# SFTP Server
resource "aws_transfer_server" "transfer_server" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.transfer_server_role.arn
  endpoint_type          = "PUBLIC"
  tags                   = {
    Project              = "peter-sftp-tf"
  }
}

resource "aws_transfer_user" "transfer_server_users" {
  # for_each = var.TRANSFER_SERVER_USERS
  count = length(var.TRANSFER_SERVER_USERS)
  server_id = aws_transfer_server.transfer_server.id
  user_name = var.TRANSFER_SERVER_USERS[count.index]
  home_directory = "/${var.S3_BUCKET_NAME}/${var.TRANSFER_SERVER_USERS[count.index]}"
  role           = aws_iam_role.transfer_server_role.arn
}

# resource "aws_transfer_user" "transfer_server_user" {
#   server_id      = aws_transfer_server.transfer_server.id
#   user_name      = var.TRANSFER_SERVER_USERNAME_LIST
#   role           = aws_iam_role.transfer_server_role.arn
#   home_directory = "/${var.S3_BUCKET_NAME}"
# }

resource "aws_transfer_ssh_key" "transfer_server_ssh_key" {
  count = length(var.TRANSFER_SERVER_USERS)
  server_id = aws_transfer_server.transfer_server.id
  user_name = aws_transfer_user.transfer_server_users[count.index].user_name
  body      = file("sftp.pub")
}


# Route 53
resource "aws_route53_zone" "peter_sftp_zone" {
  name      = "pkang-sftp.com"
  tags      = {
    Project = "peter-sftp-tf"
  }
}

resource "aws_route53_record" "cname-record" {
  zone_id = aws_route53_zone.peter_sftp_zone.zone_id
  name    = "test"
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_transfer_server.transfer_server.endpoint ]
}
