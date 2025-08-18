#!/bin/bash

# Terraform S3 Backend Setup Script with Native State Locking
# This script creates the necessary AWS resources for Terraform remote state
# Uses S3 native locking (Terraform 1.6+) - no DynamoDB required!

set -e

# Configuration variables - UPDATE THESE VALUES
BUCKET_NAME="chinmayto-terraform-state-bucket-$(date +%s)"
REGION="us-east-1"

echo "Setting up Terraform S3 backend with native state locking..."
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo "Note: Using S3 native locking - no DynamoDB table needed!"
echo ""

# Create S3 bucket for state storage
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning on the bucket (recommended for state files)
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Block public access
echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo ""
echo "✅ Backend setup complete!"
echo ""
echo "Update your providers.tf with the following backend configuration:"
echo ""
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket                      = \"$BUCKET_NAME\""
echo "    key                         = \"eks-cluster/terraform.tfstate\""
echo "    region                      = \"$REGION\""
echo "    encrypt                     = true"
echo "    use_lockfile               = true"
echo "    skip_requesting_account_id = false"
echo "  }"
echo "}"
echo ""
echo "Benefits of S3 Native Locking:"
echo "- No DynamoDB table required (saves cost)"
echo "- Simplified infrastructure"
echo "- Built-in with Terraform 1.6+"
echo "- Automatic lock cleanup"
echo ""
echo "Then run: terraform init -reconfigure"