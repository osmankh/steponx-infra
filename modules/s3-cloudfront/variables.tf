variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, production)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the CloudFront distribution (e.g. assets.steponx.com). Leave empty to use the default CloudFront domain."
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain. Required when domain_name is set. Must be in us-east-1."
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront distribution price class. PriceClass_100 is the cheapest (US, Canada, Europe)."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
