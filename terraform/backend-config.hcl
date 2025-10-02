# Terraform Backend Configuration
# This file configures the S3 backend for storing Terraform state
# Use with: terraform init -backend-config=backend-config.hcl

bucket = "hello-world-terraform-state-waynekennedy"
key    = "hello-world/terraform.tfstate"
region = "us-east-1"

# Enable state locking and consistency checking via DynamoDB
dynamodb_table = "hello-world-terraform-locks"
encrypt        = true