output "transfer_server_id" {
  value = aws_transfer_server.transfer_server.id
}

output "transfer_server_endpoint" {
  value = aws_transfer_server.transfer_server.endpoint
}

output "eip1_private_ip" {
  value = aws_eip.sftp_eip1.private_ip
}

output "eip1_public_ip" {
  value = aws_eip.sftp_eip1.public_ip
}

output "eip2_private_ip" {
  value = aws_eip.sftp_eip2.private_ip
}

output "eip2_public_ip" {
  value = aws_eip.sftp_eip2.public_ip
}

output "nlb_id" {
  value = aws_lb.sftp_nlb.id
}

output "nlb_dns_name" {
  value = aws_lb.sftp_nlb.dns_name
}

output "nlb_target_group_id" {
  value = aws_lb_target_group.nlb_target_group.id
}

output "nlb_target_group_arn" {
  value = aws_lb_target_group.nlb_target_group.arn
}
