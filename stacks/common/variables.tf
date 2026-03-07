variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "steponx"
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "domain_name" {
  description = "Primary domain for SES and CloudFront"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# DNS / Route 53
# -----------------------------------------------------------------------------

variable "create_hosted_zone" {
  description = "Create a Route 53 hosted zone for the domain (enable only in one environment)"
  type        = bool
  default     = false
}

variable "create_acm_certificate" {
  description = "Create an ACM certificate for the environment domains with DNS validation"
  type        = bool
  default     = false
}

variable "acm_domain_names" {
  description = "Domain names for the ACM certificate (first is primary, rest are SANs)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Media Bucket (S3 + optional CloudFront)
# -----------------------------------------------------------------------------

variable "enable_media_bucket" {
  description = "Enable the S3 media bucket for product images and uploads"
  type        = bool
  default     = true
}

variable "media_cloudfront_enabled" {
  description = "Enable CloudFront distribution for the media bucket"
  type        = bool
  default     = false
}

variable "media_allowed_origins" {
  description = "Origins allowed to upload files to the media bucket via CORS"
  type        = list(string)
  default     = ["*"]
}

# -----------------------------------------------------------------------------
# Cognito
# -----------------------------------------------------------------------------

variable "cognito_callback_urls" {
  description = "Allowed callback URLs for Cognito user pool client"
  type        = list(string)
  default     = ["http://localhost:3000/api/auth/callback"]
}

variable "cognito_logout_urls" {
  description = "Allowed logout URLs for Cognito user pool client"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs for network monitoring"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
