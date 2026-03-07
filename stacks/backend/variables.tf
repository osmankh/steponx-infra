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
# Web Container / ECS
# -----------------------------------------------------------------------------

variable "container_image" {
  description = "Docker image for the Next.js app, e.g. 495599775261.dkr.ecr.eu-central-1.amazonaws.com/steponx-production:latest"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "Port the web container listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the web ECS task (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MiB for the web ECS task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of web ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of web ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of web ECS tasks for auto-scaling"
  type        = number
  default     = 4
}

# -----------------------------------------------------------------------------
# API Container / ECS
# -----------------------------------------------------------------------------

variable "api_container_image" {
  description = "Docker image for the API server"
  type        = string
  default     = ""
}

variable "api_container_port" {
  description = "Port the API container listens on"
  type        = number
  default     = 3001
}

variable "api_cpu" {
  description = "CPU units for the API ECS task"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory in MiB for the API ECS task"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired number of API ECS tasks"
  type        = number
  default     = 1
}

variable "api_min_capacity" {
  description = "Minimum number of API ECS tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Maximum number of API ECS tasks for auto-scaling"
  type        = number
  default     = 4
}

variable "api_host_header" {
  description = "Host header for API routing (e.g. api.steponx.com). Required to enable API listener rules."
  type        = string
  default     = ""
}

variable "api_environment_variables" {
  description = "Extra environment variables for the API container"
  type        = map(string)
  default     = {}
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

variable "enable_load_balancer" {
  description = "Enable ALB and attach ECS service to it (requires account verification for ELBv2)"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# DNS (Route 53)
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name (e.g. steponx.com)"
  type        = string
  default     = ""
}

variable "create_dns_records" {
  description = "Create Route 53 DNS records pointing to the ALB"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for DNS records"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Application
# -----------------------------------------------------------------------------

variable "app_environment_variables" {
  description = "Extra environment variables to pass to the web container"
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
