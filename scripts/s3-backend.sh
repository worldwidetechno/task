#!/bin/bash

AWS_REGION="us-east-1"
BUCKET_NAME="world_wide_backend_30042026"

echo "Creating S3 bucket: $BUCKET_NAME in $AWS_REGION"

aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Bucket created successfully"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $AWS_REGION"
echo "Versioning: Enabled"
echo "Encryption: AES256"
