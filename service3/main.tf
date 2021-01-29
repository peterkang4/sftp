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

data "aws_eip" "eip1_data" {
  depends_on = [ aws_transfer_server.transfer_server, aws_eip.sftp_eip1 ]
  tags       = {
    Name     = "sftp_eip1"
  }
}

data "aws_eip" "eip2_data" {
  depends_on = [ aws_transfer_server.transfer_server, aws_eip.sftp_eip2 ]
  tags       = {
    Name     = "sftp_eip2"
  }
}

###########
# RESOURCES
###########
resource "aws_security_group" "sftp_securitygroup" {
  name          = "sftp_securitygroup"
  vpc_id        = var.VPC_ID
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags          = {
    Project     = "peter-sftp-tf"
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
  identity_provider_type   = var.SFTP_IDENTITY_PROVIDER_TYPE
  logging_role             = aws_iam_role.transfer_server_role.arn
  endpoint_type            = "VPC"

  endpoint_details {
    address_allocation_ids = [ aws_eip.sftp_eip1.id, aws_eip.sftp_eip2.id ]
    subnet_ids             = [ var.SUBNET1, var.SUBNET2 ]
    vpc_id                 = var.VPC_ID
  }
  tags                     = {
    Project                = "peter-sftp-tf"
    Name                   = "peter-sftp"
  }
}

resource "aws_transfer_user" "transfer_server_users" {
  count          = length(var.TRANSFER_SERVER_USERS)
  server_id      = aws_transfer_server.transfer_server.id
  user_name      = var.TRANSFER_SERVER_USERS[count.index]
  home_directory = "/${var.S3_BUCKET_NAME}/${var.TRANSFER_SERVER_USERS[count.index]}"
  role           = aws_iam_role.transfer_server_role.arn
}

resource "aws_transfer_ssh_key" "transfer_server_ssh_key" {
  count     = length(var.TRANSFER_SERVER_USERS)
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


# NLB
resource "aws_lb" "sftp_nlb" {
  name                       = "sftp-nlb"
  internal                   = false
  load_balancer_type         = "network"
  enable_deletion_protection = false
  subnets                    = [ var.SUBNET1, var.SUBNET2 ]
  tags = {
    Project                  = "peter-sftp-tf"
  }
}

resource "aws_lb_target_group" "nlb_target_group" {
  name                 = "nlb-target-group"
  port                 = 22
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.VPC_ID
  deregistration_delay = 3600
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn  = aws_lb.sftp_nlb.arn
  port               = "22"
  protocol           = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

# EIP
resource "aws_eip" "sftp_eip1" {
  vpc       = true
  tags      = {
    Project = "peter-sftp-tf"
    Name    = "sftp_eip1"
  }
}

resource "aws_eip" "sftp_eip2" {
  vpc       = true
  tags      = {
    Project = "peter-sftp-tf"
    Name    = "sftp_eip2"
  }
}

# NLB TG Attachments
resource "aws_lb_target_group_attachment" "nlb_tg1_private_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        =   data.aws_eip.eip1_data.private_ip
}

resource "aws_lb_target_group_attachment" "nlb_tg2_private_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = data.aws_eip.eip2_data.private_ip
}
