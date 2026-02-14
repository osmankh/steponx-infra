variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID to deploy the service into"
  type        = string
}

variable "task_family" {
  description = "Task definition family name (e.g. web, worker)"
  type        = string
}

variable "container_image" {
  description = "Docker image URI for the container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for the task (1 vCPU = 1024)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MiB for the task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 4
}

variable "target_group_arn" {
  description = "ALB target group ARN for the service (empty string to skip load balancer attachment)"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for task placement"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the service runs"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB to allow ingress from (empty string to skip ALB ingress rule)"
  type        = string
  default     = ""
}

variable "environment_variables" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets to inject into the container (values are SSM/Secrets Manager ARNs)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
