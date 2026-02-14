output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener (redirect if certificate exists, forward otherwise)"
  value       = try(aws_lb_listener.http_redirect[0].arn, aws_lb_listener.http_forward[0].arn)
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener, empty string if no certificate is provided"
  value       = try(aws_lb_listener.https[0].arn, "")
}
