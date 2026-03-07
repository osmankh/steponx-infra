output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.assets.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution (empty when CloudFront is disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.this[0].id : ""
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution (empty when CloudFront is disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.this[0].domain_name : ""
}

output "cloudfront_arn" {
  description = "ARN of the CloudFront distribution (empty when CloudFront is disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.this[0].arn : ""
}

output "oac_id" {
  description = "ID of the CloudFront Origin Access Control (empty when CloudFront is disabled)"
  value       = var.enable_cloudfront ? aws_cloudfront_origin_access_control.this[0].id : ""
}
