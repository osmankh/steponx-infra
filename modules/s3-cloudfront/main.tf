terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  bucket_name       = "${var.project_name}-${var.environment}-assets"
  has_custom_domain = var.domain_name != ""
}

# -----------------------------------------------------------------------------
# S3 Bucket — Private asset storage
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = local.has_custom_domain ? ["https://${var.domain_name}"] : ["https://${aws_cloudfront_distribution.this.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${local.bucket_name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "this" {
  comment             = "${var.project_name} ${var.environment} asset distribution"
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = local.has_custom_domain ? [var.domain_name] : []
  wait_for_deployment = false

  origin {
    domain_name              = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id                = "s3-${local.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${local.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  dynamic "viewer_certificate" {
    for_each = local.has_custom_domain ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.has_custom_domain ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Managed Cache Policy — CachingOptimized
# -----------------------------------------------------------------------------

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy — Allow CloudFront OAC access
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOACAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.assets.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.assets]
}
