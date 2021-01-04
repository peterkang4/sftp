# IAM
resource "aws_iam_instance_profile" "sftp_instance_profile" {
  name = "sftp_instance_profile"
  role = aws_iam_role.peter-sftp-service-role.name
  path = "/"
}

resource "aws_iam_role" "peter-sftp-service-role" {
  name               = "peter-sftp-service-role"
  description        = "SFTP service role for S3"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "AllowTransfer"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "peter-sftp-service-policy" {
  name        = "peter-sftp-service-policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:List*",
        "s3:Get*",
        "s3:Put*"
      ],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::peterkang-sftp-bucket", "arn:aws:s3:::peterkang-sftp-bucket/*"]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "peter-sftp-policy-role-attachment" {
  name       = "peter-sftp-policy-role-attachment"
  roles      = [ aws_iam_role.peter-sftp-service-role.name ]
  policy_arn = aws_iam_policy.peter-sftp-service-policy.arn
}

# EC2
resource "aws_security_group" "sftp-securitygroup" {
  name          = "sftp-securitygroup"
  vpc_id        = var.VPC_ID
  ingress {
    description = "SFTP/SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags          = {
    Name        = "peter-sftp"
    User        = "Peter Kang"
    Project     = "Peter SFTP"
  }
}


###################


resource "aws_launch_configuration" "peter-sftp-lc" {
  name_prefix   = "peter-sftp-lc"
  image_id      = "ami-0be2609ba883822ec"
  instance_type = "t2.micro"
  iam_instance_profile = "sftp_instance_profile"
  key_name = var.KEY_NAME
  associate_public_ip_address = true
  security_groups = [ aws_security_group.sftp-securitygroup.id ]

  lifecycle {
    create_before_destroy = true
  }

  # Block device mappings
  root_block_device {
    volume_type = "gp2"
    volume_size = 10
    delete_on_termination = true
  }

  # User Data

}

resource "aws_autoscaling_group" "peter-sftp-asg" {
  name                = "peter-sftp-asg"
  launch_configuration = aws_launch_configuration.peter-sftp-lc.name
  min_size            = 1
  max_size            = 1
  vpc_zone_identifier  = [ var.SUBNET1, var.SUBNET2 ]

  lifecycle {
    create_before_destroy = true
  }
}




###################

# resource "aws_instance" "peter_sftp" {
#   ami                    = "ami-0be2609ba883822ec"  # Amazon Linux, us-east-1
#   instance_type          = "t2.micro"
#   subnet_id              = var.SUBNET1
#   key_name               = var.KEY_NAME
#   iam_instance_profile    = "sftp_instance_profile"
#   vpc_security_group_ids = [ aws_security_group.sftp-securitygroup.id ]
#   associate_public_ip_address = true
#   root_block_device {
#     volume_type = "gp2"
#     volume_size = 10
#   }
#   tags   = {
#     Name = "peter_sftp"
#     User        = "Peter Kang"
#     Project     = "Peter SFTP"
#   }
# }
