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

variable "subnet_ids" {
  description = "List of subnet IDs for task placement"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to ECS tasks"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block for scoping egress rules"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "VPC ID where the service runs"
  type        = string
}

variable "enable_alb_ingress" {
  description = "Whether to create the ALB ingress security group rule"
  type        = bool
  default     = false
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB to allow ingress from"
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

variable "service_name" {
  description = "Short name for the service, used in IAM role names to avoid collisions across module instances"
  type        = string
  default     = ""
}

variable "health_check_command" {
  description = "Container health check command. Empty list disables container health check."
  type        = list(string)
  default     = []
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to wait before ECS starts checking ALB health for new tasks"
  type        = number
  default     = 60
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower bound on running tasks during deployment (100 = never fewer than desired_count)"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Upper bound on running tasks during deployment (200 = allow double for rolling update)"
  type        = number
  default     = 200
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
