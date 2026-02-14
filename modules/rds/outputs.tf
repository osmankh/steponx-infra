output "db_instance_endpoint" {
  description = "The connection endpoint of the RDS instance (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The port the RDS instance is listening on"
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "The name of the default database"
  value       = aws_db_instance.this.db_name
}

output "db_security_group_id" {
  description = "The ID of the security group attached to the RDS instance"
  value       = aws_security_group.this.id
}

output "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_instance_id" {
  description = "The identifier of the RDS instance"
  value       = aws_db_instance.this.id
}
