terraform {
    backend "s3" {
        bucket = "peter-remote-tf-backend"
        key    = "tf/peter-sftp-storage"
    }
}