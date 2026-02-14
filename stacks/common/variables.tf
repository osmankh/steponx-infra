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

variable "cdn_domain_name" {
  description = "Custom domain for CloudFront distribution"
  type        = string
  default     = ""
}

variable "cdn_acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}

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

variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs for network monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
