# S3 Backend Configuration with Native State Locking
# 
# This configuration uses S3's native state locking feature (introduced in Terraform 1.6+)
# which eliminates the need for a separate DynamoDB table.
#
# Before using this backend, you need to:
# 1. Create an S3 bucket for storing Terraform state
# 2. Enable versioning on the bucket (recommended)
# 3. Update the values below with your actual bucket name and region
#
# Example setup commands:
# aws s3 mb s3://chinmayto-terraform-state-bucket --region us-east-1
# aws s3api put-bucket-versioning --bucket chinmayto-terraform-state-bucket --versioning-configuration Status=Enabled
# aws s3api put-bucket-encryption --bucket chinmayto-terraform-state-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Backend configuration (already configured in providers.tf):
# terraform {
#   backend "s3" {
#     bucket                      = "chinmayto-terraform-state-bucket-name"
#     key                         = "eks-cluster/terraform.tfstate"
#     region                      = "us-east-1"
#     encrypt                     = true
#     use_lockfile               = true
#     skip_requesting_account_id = false
#   }
# }

# Benefits of S3 Native Locking:
# - No additional DynamoDB table required
# - Simplified infrastructure
# - Lower cost (no DynamoDB charges)
# - Built-in with Terraform 1.6+
# - Automatic cleanup of lock files