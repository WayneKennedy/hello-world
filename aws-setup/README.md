# AWS Setup Instructions for Hello World DevOps Pipeline

## 🚀 Quick Setup Guide

### Step 1: Create AWS IAM User

1. **Log into AWS Console**: Go to [AWS IAM Console](https://console.aws.amazon.com/iam/)

2. **Create New User**:
   ```bash
   # User Details
   User name: hello-world-deployer
   Access type: Programmatic access (Access key - Programmatic access)
   ```

3. **Attach Custom Policy**:
   - Create a new policy using the `iam-policy.json` file in this directory
   - Copy the JSON content and paste it into the policy editor
   - Name the policy: `HelloWorldDeploymentPolicy`

### Step 2: Get AWS Credentials

After creating the user, AWS will provide:
- **Access Key ID** (example: `AKIAIOSFODNN7EXAMPLE`)
- **Secret Access Key** (example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

⚠️ **IMPORTANT**: Save these credentials securely - you won't be able to see the secret key again!

### Step 3: Configure GitHub Secrets

1. **Go to GitHub Repository Settings**:
   - Navigate to your repository on GitHub
   - Go to Settings → Secrets and variables → Actions

2. **Add Repository Secrets**:
   ```
   Name: AWS_ACCESS_KEY_ID
   Value: [Your Access Key ID from Step 2]
   
   Name: AWS_SECRET_ACCESS_KEY  
   Value: [Your Secret Access Key from Step 2]
   ```

### Step 4: Verify AWS CLI Setup (Optional)

If you want to test locally:

```powershell
# Install AWS CLI (if not already installed)
winget install Amazon.AWSCLI

# Configure AWS CLI
aws configure
# Enter your Access Key ID
# Enter your Secret Access Key  
# Default region: us-east-1
# Default output format: json

# Test the connection
aws sts get-caller-identity
```

## 🔧 AWS Resources Created

The Terraform configuration will create:

### S3 Bucket
- **Purpose**: Static website hosting
- **Features**: 
  - Versioning enabled
  - Server-side encryption (AES256)
  - Optimized for CloudFront delivery
  - Automatic cleanup policies

### CloudFront Distribution
- **Purpose**: Global CDN for fast content delivery
- **Features**:
  - HTTPS-only access
  - Optimized caching rules
  - Custom error pages for SPA routing
  - Origin Access Control (OAC) for security

### Security Features
- Origin Access Control prevents direct S3 access
- HTTPS redirect for all traffic
- Encrypted storage
- Least-privilege IAM permissions

## 💰 Cost Estimation

For a simple Hello World site:
- **S3**: ~$0.01-0.05/month (depending on traffic)
- **CloudFront**: ~$0.10-1.00/month (12 months free tier)
- **Total**: Under $1/month for typical usage

## 🧹 Cleanup Instructions

To avoid ongoing charges, you can destroy the infrastructure:

```powershell
# Navigate to terraform directory
cd terraform

# Destroy all resources
terraform destroy -var="bucket_name=hello-world-your-username-123"
```

Or use the GitHub Actions workflow to automatically clean up resources.

## 🔍 Troubleshooting

### Common Issues:

1. **"Access Denied" errors**:
   - Verify IAM policy is correctly attached
   - Check AWS credentials in GitHub secrets

2. **Terraform state issues**:
   - The configuration uses local state by default
   - For production, consider using S3 remote state

3. **CloudFront propagation**:
   - CloudFront changes can take 15-45 minutes to propagate globally
   - Be patient after initial deployment

4. **Bucket name conflicts**:
   - S3 bucket names must be globally unique
   - The workflow uses GitHub run number to ensure uniqueness

### Getting Help:

- Check the GitHub Actions logs for detailed error messages
- Review AWS CloudTrail for API call details
- Use AWS Support Center for AWS-specific issues

## 🎯 Next Steps

1. **Custom Domain**: Add Route 53 DNS and SSL certificate
2. **Monitoring**: Set up CloudWatch dashboards and alarms
3. **Security**: Implement AWS Config rules and Security Hub
4. **Performance**: Add additional CloudFront optimizations
5. **Automation**: Add scheduled deployments and rollback capabilities