###########
# DATA
###########

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


# NLB
resource "aws_lb" "sftp_nlb" {
  name                       = "sftp-nlb"
  load_balancer_type         = "network"
  internal                   = false
  enable_deletion_protection = false
  subnets                    = [ var.SUBNET1, var.SUBNET2 ]
  tags = {
    Project                  = "peter-sftp-tf"
    Name                     = "sftp-nlb"
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

# NLB TG Attachments
resource "aws_lb_target_group_attachment" "nlb_tg1_private_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        =   data.aws_eip.eip1_data.private_ip
}

resource "aws_lb_target_group_attachment" "nlb_tg2_private_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = data.aws_eip.eip2_data.private_ip
}


# Route 53
resource "aws_route53_zone" "sftp_zone" {
  name      = var.ADDRESS
  tags      = {
    Project = "peter-sftp-tf"
  }
}

resource "aws_route53_record" "cname-record" {
  zone_id = aws_route53_zone.sftp_zone.zone_id
  name    = "test"
  type    = "CNAME"
  ttl     = "300"
  records = [ aws_lb.sftp_nlb.dns_name ]
}


