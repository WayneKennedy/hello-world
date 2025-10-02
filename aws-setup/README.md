# AWS Setup Instructions for Hello World DevOps Pipeline

## 🚀 Quick Setup Guide

### Step 1: Create AWS IAM User

#### 🖥️ **Detailed AWS Console Steps:**

1. **Log into AWS Console**: 
   - Go to [AWS Console](https://console.aws.amazon.com/)
   - Sign in with your AWS account credentials

2. **Navigate to IAM Service**:
   - In the top search bar, type "IAM" and click on it
   - OR go directly to [AWS IAM Console](https://console.aws.amazon.com/iam/)

3. **Create New User** (Step-by-step screenshots):
   
   **Step 3a: Start User Creation**
   - Click **"Users"** in the left sidebar
   - Click the **"Create user"** button (blue button on the right)
   
   **Step 3b: User Details**
   - **User name**: `hello-world-deployer`
   - **☑️ Check**: "Provide user access to the AWS Management Console" (OPTIONAL - only if you want console access)
   - **☑️ Check**: "I want to create an IAM user" 
   - Click **"Next"**
   
   **Step 3c: Set Permissions**
   - Select **"Attach policies directly"**
   - **Don't select any existing policies** - we'll create a custom one
   - Click **"Create policy"** (this opens a new tab)

4. **Create Custom Policy** (In the new tab):
   
   **Step 4a: Policy Creation**
   - Click the **"JSON"** tab (not Visual)
   - **Delete** all the existing JSON content
   - **Copy and paste** the entire content from `aws-setup/iam-policy.json`
   
   **Step 4b: Review Policy**
   - Click **"Next: Tags"** (you can skip tags)
   - Click **"Next: Review"**
   - **Name**: `HelloWorldDeploymentPolicy`
   - **Description**: `IAM policy for Hello World DevOps pipeline deployment`
   - Click **"Create policy"**
   
   **Step 4c: Go Back to User Creation**
   - Close the policy tab and return to the user creation tab
   - Click the **refresh button** 🔄 next to the search box
   - Search for `HelloWorldDeploymentPolicy`
   - **☑️ Check the box** next to your new policy
   - Click **"Next"**

5. **Review and Create**:
   - Review all settings
   - Click **"Create user"**

6. **🔑 CRITICAL: Get Access Keys**:
   - After user creation, click on the user name `hello-world-deployer`
   - Go to **"Security credentials"** tab
   - Scroll down to **"Access keys"** section
   - Click **"Create access key"**
   - Select **"Command Line Interface (CLI)"**
   - ☑️ Check **"I understand the above recommendation..."**
   - Click **"Next"**
   - **Optional**: Add a description like "GitHub Actions deployment"
   - Click **"Create access key"**
   - **⚠️ IMPORTANT**: Copy both the **Access Key ID** and **Secret Access Key**
   - Click **"Download .csv file"** to save them securely
   - Click **"Done"**

### Step 2: Get AWS Credentials

After creating the user and access keys, you should have:
- **Access Key ID** (example: `AKIAIOSFODNN7EXAMPLE`)
- **Secret Access Key** (example: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

⚠️ **SECURITY CRITICAL**: 
- **Save these credentials securely** - you won't be able to see the secret key again!
- **Never commit these to Git** or share them publicly
- **Use a password manager** or the downloaded CSV file to store them

### Step 3: Configure GitHub Secrets

1. **Go to Your GitHub Repository**:
   - Navigate to: `https://github.com/WayneKennedy/hello-world`
   - Click **"Settings"** tab (next to About section)

2. **Navigate to Secrets**:
   - In the left sidebar, click **"Secrets and variables"**
   - Click **"Actions"**

3. **Add Repository Secrets**:
   
   **First Secret:**
   - Click **"New repository secret"**
   - **Name**: `AWS_ACCESS_KEY_ID`
   - **Secret**: [Paste your Access Key ID from Step 2]
   - Click **"Add secret"**
   
   **Second Secret:**
   - Click **"New repository secret"** again
   - **Name**: `AWS_SECRET_ACCESS_KEY`
   - **Secret**: [Paste your Secret Access Key from Step 2]
   - Click **"Add secret"**

4. **Verify Secrets**:
   - You should now see both secrets listed (values will be hidden)
   - ✅ `AWS_ACCESS_KEY_ID`
   - ✅ `AWS_SECRET_ACCESS_KEY`

## 🚀 **Test Your Setup**

Once you've completed the above steps:

1. **Trigger Deployment**:
   - Make any small change to your repository (edit README.md)
   - Commit and push: `git add . && git commit -m "Test deployment" && git push`

2. **Watch GitHub Actions**:
   - Go to your repository → **"Actions"** tab
   - You should see a workflow running
   - Click on it to watch the deployment progress

3. **Get Your Live URL**:
   - After successful deployment, the Actions log will show your CloudFront URL
   - Your site will be live at: `https://[distribution-id].cloudfront.net`

## 🆘 **Troubleshooting IAM User Creation**

### Common Issues:

**❌ "I can't find the IAM service"**
- Solution: Use the search bar at the top of AWS Console and type "IAM"

**❌ "Create policy button doesn't work"**
- Solution: Make sure you're on the "Attach policies directly" option, not "Add user to group"

**❌ "JSON policy validation failed"**
- Solution: Make sure you copied the ENTIRE content from `iam-policy.json` and deleted all existing JSON

**❌ "Access denied errors in GitHub Actions"**
- Solution: Double-check that both GitHub secrets are set correctly and your policy is attached to the user

**❌ "Can't see the secret access key"**
- Solution: You can only see it once. If you missed it, create new access keys from the Security credentials tab

### Getting Help:

- **AWS Support**: Use the question mark (?) icon in AWS Console for help
- **Check IAM Policy Simulator**: Test your permissions at https://policysim.aws.amazon.com/
- **AWS Documentation**: [IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/)

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