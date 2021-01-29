variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {}
variable "KEY_NAME" {}
variable "VPC_ID" {}
variable "SUBNET1" {}
variable "SUBNET2" {}
variable "AZ1" {}
variable "AZ2" {}
variable "S3_BUCKET_NAME" {}
variable "S3_BUCKET_ARN" {}
variable "S3_BUCKET_OBJECT_ARN" {}
variable "TRANSFER_SERVER_NAME" {}
variable "ENDPOINT_TYPE" {}
variable "SFTP_IDENTITY_PROVIDER_TYPE" {}
variable "ADDRESS" {}
variable "TRANSFER_SERVER_USERS" {
    type = list(string)
}
variable "SUBNETS" {
    type = list(string)
}