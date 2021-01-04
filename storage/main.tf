# Storage Bucket
resource "aws_s3_bucket" "peterkang_sftp_bucket" {
  bucket = "peterkang-sftp-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}

# Logging Bucket