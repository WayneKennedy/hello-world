#!/usr/bin/env pwsh
# Bootstrap script to create Terraform backend infrastructure
# This creates the S3 bucket and DynamoDB table needed for Terraform state management

param(
    [switch]$DryRun = $false
)

Write-Host "🚀 Terraform Backend Bootstrap Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

$BUCKET_NAME = "hello-world-terraform-state-waynekennedy"
$DYNAMODB_TABLE = "hello-world-terraform-locks"
$REGION = "us-east-1"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  S3 Bucket: $BUCKET_NAME" -ForegroundColor White
Write-Host "  DynamoDB Table: $DYNAMODB_TABLE" -ForegroundColor White
Write-Host "  Region: $REGION" -ForegroundColor White
Write-Host "  Dry Run: $DryRun" -ForegroundColor White

if ($DryRun) {
    Write-Host ""
    Write-Host "🔍 DRY RUN MODE - No resources will be created" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would create:" -ForegroundColor Yellow
    Write-Host "  1. S3 bucket: $BUCKET_NAME (with versioning and encryption)" -ForegroundColor White
    Write-Host "  2. DynamoDB table: $DYNAMODB_TABLE (for state locking)" -ForegroundColor White
    exit 0
}

Write-Host ""
Write-Host "🏗️  Creating Terraform backend infrastructure..." -ForegroundColor Green

# Check if bucket already exists
Write-Host "🔍 Checking if S3 bucket exists..." -ForegroundColor Blue
$bucketExists = $false
try {
    aws s3api head-bucket --bucket $BUCKET_NAME 2>$null
    if ($LASTEXITCODE -eq 0) {
        $bucketExists = $true
        Write-Host "  ✅ S3 bucket already exists: $BUCKET_NAME" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️  S3 bucket does not exist: $BUCKET_NAME" -ForegroundColor Yellow
}

# Create S3 bucket if it doesn't exist
if (-not $bucketExists) {
    Write-Host "🪣 Creating S3 bucket..." -ForegroundColor Blue
    
    # Create bucket
    aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Failed to create S3 bucket" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Created S3 bucket: $BUCKET_NAME" -ForegroundColor Green
    
    # Enable versioning
    Write-Host "🔄 Enabling S3 bucket versioning..." -ForegroundColor Blue
    aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Failed to enable versioning" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Enabled versioning" -ForegroundColor Green
    
    # Enable encryption
    Write-Host "🔐 Enabling S3 bucket encryption..." -ForegroundColor Blue
    aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Failed to enable encryption" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Enabled encryption" -ForegroundColor Green
    
    # Block public access
    Write-Host "🔒 Blocking public access..." -ForegroundColor Blue
    aws s3api put-public-access-block --bucket $BUCKET_NAME --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Failed to block public access" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✅ Blocked public access" -ForegroundColor Green
}

# Check if DynamoDB table exists
Write-Host "🔍 Checking if DynamoDB table exists..." -ForegroundColor Blue
$tableExists = $false
try {
    aws dynamodb describe-table --table-name $DYNAMODB_TABLE --region $REGION 2>$null
    if ($LASTEXITCODE -eq 0) {
        $tableExists = $true
        Write-Host "  ✅ DynamoDB table already exists: $DYNAMODB_TABLE" -ForegroundColor Green
    }
} catch {
    Write-Host "  ℹ️  DynamoDB table does not exist: $DYNAMODB_TABLE" -ForegroundColor Yellow
}

# Create DynamoDB table if it doesn't exist
if (-not $tableExists) {
    Write-Host "🗃️  Creating DynamoDB table..." -ForegroundColor Blue
    
    aws dynamodb create-table `
        --table-name $DYNAMODB_TABLE `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 `
        --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Failed to create DynamoDB table" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ⏳ Waiting for table to become active..." -ForegroundColor Yellow
    aws dynamodb wait table-exists --table-name $DYNAMODB_TABLE --region $REGION
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Table creation timed out" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  ✅ Created DynamoDB table: $DYNAMODB_TABLE" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Terraform backend infrastructure is ready!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: terraform init -backend-config=backend-config.hcl" -ForegroundColor White
Write-Host "  2. Your Terraform state will be stored in: s3://$BUCKET_NAME" -ForegroundColor White
Write-Host "  3. State locking will use DynamoDB table: $DYNAMODB_TABLE" -ForegroundColor White
Write-Host ""