variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "steponx"
}

variable "environment" {
  description = "Environment name (e.g. staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to connect to the database (e.g. ECS service SG)"
  type        = list(string)
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB for autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "steponx"
}

variable "master_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "steponx_admin"
}

variable "multi_az" {
  description = "Whether to deploy the RDS instance across multiple availability zones"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the RDS instance"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final DB snapshot when the instance is destroyed"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
