# -----------------------------------------------------------------------------
# ECR Outputs
# -----------------------------------------------------------------------------

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

# -----------------------------------------------------------------------------
# ECS Cluster Outputs
# -----------------------------------------------------------------------------

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = module.ecs_cluster.log_group_name
}

# -----------------------------------------------------------------------------
# ECS Service Outputs
# -----------------------------------------------------------------------------

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs_service.task_definition_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task IAM role (runtime permissions)"
  value       = module.ecs_service.task_role_arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution IAM role"
  value       = module.ecs_service.execution_role_arn
}

output "ecs_security_group_id" {
  description = "ID of the ECS service security group"
  value       = module.ecs_service.security_group_id
}

# -----------------------------------------------------------------------------
# ALB Outputs
# -----------------------------------------------------------------------------

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.enable_load_balancer ? module.alb[0].alb_dns_name : ""
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the ALB (for Route 53 alias records)"
  value       = var.enable_load_balancer ? module.alb[0].alb_zone_id : ""
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.enable_load_balancer ? module.alb[0].alb_arn : ""
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = var.enable_load_balancer ? module.alb[0].target_group_arn : ""
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = var.enable_load_balancer ? module.alb[0].security_group_id : ""
}

# -----------------------------------------------------------------------------
# RDS Outputs
# -----------------------------------------------------------------------------

output "rds_endpoint" {
  description = "Connection endpoint of the RDS instance (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "Port the RDS instance listens on"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "Name of the default database"
  value       = module.rds.db_instance_name
}

output "rds_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = module.rds.db_secret_arn
  sensitive   = true
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds.db_security_group_id
}
