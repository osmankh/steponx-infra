output "bucket_name" {
  description = "Name of the S3 assets bucket"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "ARN of the S3 assets bucket"
  value       = aws_s3_bucket.assets.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "oac_id" {
  description = "ID of the CloudFront Origin Access Control"
  value       = aws_cloudfront_origin_access_control.this.id
}
