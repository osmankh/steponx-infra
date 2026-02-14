# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = module.vpc.nat_gateway_id
}

# -----------------------------------------------------------------------------
# CDN Outputs
# -----------------------------------------------------------------------------

output "cdn_bucket_name" {
  description = "Name of the S3 bucket for CDN assets"
  value       = module.cdn.bucket_name
}

output "cdn_bucket_arn" {
  description = "ARN of the S3 bucket for CDN assets"
  value       = module.cdn.bucket_arn
}

output "cdn_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_id
}

output "cdn_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_domain_name
}

# -----------------------------------------------------------------------------
# SES Outputs (conditional)
# -----------------------------------------------------------------------------

output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = var.domain_name != "" ? module.ses[0].domain_identity_arn : ""
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for DNS verification"
  value       = var.domain_name != "" ? module.ses[0].dkim_tokens : []
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = var.domain_name != "" ? module.ses[0].configuration_set_name : ""
}

output "ses_send_policy_arn" {
  description = "ARN of the IAM policy for SES sending"
  value       = var.domain_name != "" ? module.ses[0].ses_send_policy_arn : ""
}

# -----------------------------------------------------------------------------
# Cognito Outputs
# -----------------------------------------------------------------------------

output "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "ARN of the Cognito user pool"
  value       = module.cognito.user_pool_arn
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito user pool client"
  value       = module.cognito.user_pool_client_id
}

output "cognito_user_pool_endpoint" {
  description = "Endpoint of the Cognito user pool"
  value       = module.cognito.user_pool_endpoint
}
