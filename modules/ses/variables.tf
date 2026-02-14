variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)"
  type        = string
}

variable "domain_name" {
  description = "The email domain to verify with SES (e.g. steponx.com)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
