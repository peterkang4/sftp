# sftp

Existing resources:
1. VPC
2. Subnets

Resources needed:

1. Linux EC2 Server
2. EC2 Security Group
    a. port 22 for SFTP(change for later?)
3. IAM Role
    a. Read, Put to S3
4. Route 53 for DNS entry/ public IP address
5. S3
    a. Needs S3 DATA storage bucket, interacts with S3 service
    b. Needs S3 LOG bucket, stores activity of Data bucket