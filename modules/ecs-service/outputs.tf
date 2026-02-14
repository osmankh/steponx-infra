output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "task_role_arn" {
  description = "ARN of the task IAM role (used by the application at runtime)"
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "ARN of the execution IAM role (used by ECS agent)"
  value       = aws_iam_role.execution.arn
}

output "security_group_id" {
  description = "ID of the ECS service security group"
  value       = aws_security_group.ecs_service.id
}
