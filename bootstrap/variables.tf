variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "steponx"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "github_org" {
  description = "GitHub organization or user that owns the infrastructure repo"
  type        = string
  default     = "osmankh"
}

variable "github_repo" {
  description = "GitHub repository name for infrastructure code"
  type        = string
  default     = "steponx-infra"
}

variable "environment" {
  description = "Environment label (e.g. bootstrap, staging, production)"
  type        = string
  default     = "bootstrap"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
