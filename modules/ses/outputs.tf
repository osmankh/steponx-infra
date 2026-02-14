output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.this.arn
}

output "dkim_tokens" {
  description = "List of DKIM tokens. Create CNAME records: <token>._domainkey.<domain> -> <token>.dkim.amazonses.com"
  value       = aws_ses_domain_dkim.this.dkim_tokens
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.this.name
}

output "bounce_topic_arn" {
  description = "ARN of the SNS topic for bounce notifications"
  value       = aws_sns_topic.bounces.arn
}

output "complaint_topic_arn" {
  description = "ARN of the SNS topic for complaint notifications"
  value       = aws_sns_topic.complaints.arn
}

output "ses_send_policy_arn" {
  description = "ARN of the IAM managed policy for sending email via SES"
  value       = aws_iam_policy.ses_send.arn
}
