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
# Media Bucket Outputs
# -----------------------------------------------------------------------------

output "media_bucket_name" {
  description = "Name of the S3 media bucket"
  value       = var.enable_media_bucket ? module.media[0].bucket_name : ""
}

output "media_bucket_arn" {
  description = "ARN of the S3 media bucket"
  value       = var.enable_media_bucket ? module.media[0].bucket_arn : ""
}

output "media_cloudfront_domain_name" {
  description = "Domain name of the media CloudFront distribution (empty when disabled)"
  value       = var.enable_media_bucket && var.media_cloudfront_enabled ? module.media[0].cloudfront_domain_name : ""
}

output "media_base_url" {
  description = "Base URL for media access (CloudFront URL if enabled, otherwise S3 regional domain)"
  value       = var.enable_media_bucket ? (var.media_cloudfront_enabled ? "https://${module.media[0].cloudfront_domain_name}" : "https://${module.media[0].bucket_regional_domain_name}") : ""
}

# -----------------------------------------------------------------------------
# DNS / Route 53 Outputs
# -----------------------------------------------------------------------------

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = local.zone_id
}

output "route53_name_servers" {
  description = "Name servers for the hosted zone (add these at your registrar)"
  value       = var.create_hosted_zone && var.domain_name != "" ? aws_route53_zone.main[0].name_servers : []
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.create_acm_certificate && length(var.acm_domain_names) > 0 ? aws_acm_certificate.main[0].arn : ""
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
