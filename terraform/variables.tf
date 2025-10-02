# Environment-specific variables
variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hello-world"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Generate consistent resource names
locals {
  # Create a consistent naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Environment-specific configuration
  environment_config = {
    dev = {
      cloudfront_price_class = "PriceClass_100"  # North America and Europe only
      cache_ttl_default     = 300               # 5 minutes for faster dev iteration
      cache_ttl_max         = 3600              # 1 hour max
    }
    test = {
      cloudfront_price_class = "PriceClass_100"  # North America and Europe only
      cache_ttl_default     = 1800              # 30 minutes
      cache_ttl_max         = 7200              # 2 hours max
    }
    prod = {
      cloudfront_price_class = "PriceClass_All"  # Global distribution
      cache_ttl_default     = 86400             # 1 day
      cache_ttl_max         = 31536000          # 1 year max
    }
  }
  
  # Get current environment config
  current_config = local.environment_config[var.environment]
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Workspace   = terraform.workspace
  }
}