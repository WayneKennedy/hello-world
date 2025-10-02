#!/usr/bin/env pwsh

# Cleanup script for orphaned Hello World AWS resources
# This script helps clean up S3 buckets and CloudFront distributions from previous deployments

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false
)

Write-Host "🧹 Hello World AWS Resource Cleanup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "   Install with: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $identity = aws sts get-caller-identity --output json 2>$null | ConvertFrom-Json
    Write-Host "✅ AWS Credentials: $($identity.Arn)" -ForegroundColor Green
}
catch {
    Write-Host "❌ AWS credentials not configured or invalid" -ForegroundColor Red
    Write-Host "   Configure with: aws configure" -ForegroundColor Yellow
    exit 1
}

function Get-HelloWorldS3Buckets {
    Write-Host "🔍 Finding Hello World S3 buckets..." -ForegroundColor Blue
    
    $buckets = @()
    $allBuckets = aws s3api list-buckets --query 'Buckets[].Name' --output text 2>$null
    
    if ($allBuckets) {
        foreach ($bucket in $allBuckets -split "`t") {
            if ($bucket -match "^hello-world-") {
                $buckets += $bucket
                Write-Host "   Found: $bucket" -ForegroundColor Yellow
            }
        }
    }
    
    return $buckets
}

function Get-HelloWorldCloudFrontDistributions {
    Write-Host "🔍 Finding Hello World CloudFront distributions..." -ForegroundColor Blue
    
    $distributions = @()
    $allDistributions = aws cloudfront list-distributions --output json 2>$null | ConvertFrom-Json
    
    if ($allDistributions.DistributionList.Items) {
        foreach ($dist in $allDistributions.DistributionList.Items) {
            if ($dist.Comment -match "hello-world.*static website") {
                $distributions += @{
                    Id = $dist.Id
                    DomainName = $dist.DomainName
                    Comment = $dist.Comment
                    Status = $dist.Status
                }
                Write-Host "   Found: $($dist.Id) - $($dist.Comment)" -ForegroundColor Yellow
            }
        }
    }
    
    return $distributions
}

function Remove-S3Bucket {
    param($BucketName)
    
    Write-Host "🗑️  Removing S3 bucket: $BucketName" -ForegroundColor Red
    
    if ($DryRun) {
        Write-Host "   [DRY RUN] Would delete bucket: $BucketName" -ForegroundColor Magenta
        return
    }
    
    try {
        # Empty the bucket first
        Write-Host "   Emptying bucket contents..." -ForegroundColor Blue
        aws s3 rm "s3://$BucketName" --recursive 2>$null
        
        # Delete the bucket
        Write-Host "   Deleting bucket..." -ForegroundColor Blue
        aws s3api delete-bucket --bucket $BucketName 2>$null
        
        Write-Host "   ✅ Successfully deleted: $BucketName" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌ Failed to delete: $BucketName" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
}

function Remove-CloudFrontDistribution {
    param($Distribution)
    
    Write-Host "🗑️  Removing CloudFront distribution: $($Distribution.Id)" -ForegroundColor Red
    
    if ($DryRun) {
        Write-Host "   [DRY RUN] Would delete distribution: $($Distribution.Id)" -ForegroundColor Magenta
        return
    }
    
    try {
        if ($Distribution.Status -eq "Deployed") {
            Write-Host "   Disabling distribution..." -ForegroundColor Blue
            
            # Get current config
            $config = aws cloudfront get-distribution-config --id $Distribution.Id --output json | ConvertFrom-Json
            
            # Disable the distribution
            $config.DistributionConfig.Enabled = $false
            $configJson = $config.DistributionConfig | ConvertTo-Json -Depth 10
            $configJson | Out-File -FilePath "temp-config.json" -Encoding UTF8
            
            aws cloudfront update-distribution --id $Distribution.Id --distribution-config file://temp-config.json --if-match $config.ETag 2>$null
            Remove-Item "temp-config.json" -ErrorAction SilentlyContinue
            
            Write-Host "   ⏳ Distribution disabled. Wait for deployment before deletion." -ForegroundColor Yellow
            Write-Host "   💡 Run this script again in 15-20 minutes to complete deletion." -ForegroundColor Cyan
        }
        else {
            Write-Host "   Distribution not in Deployed status: $($Distribution.Status)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "   ❌ Failed to disable distribution: $($Distribution.Id)" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
    }
}

# Main cleanup logic
Write-Host ""
Write-Host "🎯 Environment filter: $Environment" -ForegroundColor Cyan
Write-Host "🔍 Dry run mode: $DryRun" -ForegroundColor Cyan
Write-Host ""

# Get resources
$s3Buckets = Get-HelloWorldS3Buckets
$cloudFrontDistributions = Get-HelloWorldCloudFrontDistributions

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   S3 Buckets: $($s3Buckets.Count)" -ForegroundColor White
Write-Host "   CloudFront Distributions: $($cloudFrontDistributions.Count)" -ForegroundColor White
Write-Host ""

if ($s3Buckets.Count -eq 0 -and $cloudFrontDistributions.Count -eq 0) {
    Write-Host "✅ No Hello World resources found to clean up!" -ForegroundColor Green
    exit 0
}

# Confirmation
if (-not $Force -and -not $DryRun) {
    Write-Host "⚠️  This will DELETE the resources listed above!" -ForegroundColor Red
    $confirmation = Read-Host "Type 'DELETE' to confirm"
    if ($confirmation -ne "DELETE") {
        Write-Host "❌ Cleanup cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Clean up S3 buckets
if ($s3Buckets.Count -gt 0) {
    Write-Host "🧹 Cleaning up S3 buckets..." -ForegroundColor Blue
    foreach ($bucket in $s3Buckets) {
        if ($Environment -eq "all" -or $bucket -match "-$Environment-") {
            Remove-S3Bucket -BucketName $bucket
        }
        else {
            Write-Host "   Skipping $bucket (doesn't match environment filter)" -ForegroundColor Gray
        }
    }
}

# Clean up CloudFront distributions
if ($cloudFrontDistributions.Count -gt 0) {
    Write-Host "🧹 Cleaning up CloudFront distributions..." -ForegroundColor Blue
    foreach ($dist in $cloudFrontDistributions) {
        if ($Environment -eq "all" -or $dist.Comment -match "-$Environment-") {
            Remove-CloudFrontDistribution -Distribution $dist
        }
        else {
            Write-Host "   Skipping $($dist.Id) (doesn't match environment filter)" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "🎉 Cleanup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "   • Use --DryRun to preview changes" -ForegroundColor White
Write-Host "   • Use -Environment dev/test/prod to target specific environments" -ForegroundColor White
Write-Host "   • CloudFront distributions need time to disable before deletion" -ForegroundColor White