variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, production)"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of untagged images to retain in the repository"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
