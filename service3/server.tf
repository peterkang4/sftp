

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







