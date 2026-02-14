# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "steponx"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

# -----------------------------------------------------------------------------
# Container / ECS
# -----------------------------------------------------------------------------

variable "container_image" {
  description = "Docker image for the Next.js app, e.g. 495599775261.dkr.ecr.eu-central-1.amazonaws.com/steponx-production:latest"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the ECS task (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MiB for the ECS task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks for auto-scaling"
  type        = number
  default     = 4
}

# -----------------------------------------------------------------------------
# Database (RDS)
# -----------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for the RDS instance"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# ALB / Networking
# -----------------------------------------------------------------------------

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Application
# -----------------------------------------------------------------------------

variable "app_environment_variables" {
  description = "Extra environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
