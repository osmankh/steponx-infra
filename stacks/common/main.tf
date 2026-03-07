module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = var.enable_vpc_flow_logs
  tags               = var.tags
}

module "media" {
  source = "../../modules/s3-cloudfront"
  count  = var.enable_media_bucket ? 1 : 0

  project_name           = var.project_name
  environment            = var.environment
  bucket_suffix          = "media"
  enable_cloudfront      = var.media_cloudfront_enabled
  allowed_upload_origins = var.media_allowed_origins
  tags                   = var.tags
}

# -----------------------------------------------------------------------------
# Route 53 Hosted Zone
# -----------------------------------------------------------------------------

resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone && var.domain_name != "" ? 1 : 0
  name  = var.domain_name
  tags  = var.tags
}

locals {
  zone_id = var.create_hosted_zone && var.domain_name != "" ? aws_route53_zone.main[0].zone_id : var.route53_zone_id
}

# -----------------------------------------------------------------------------
# ACM Certificate (DNS validated via Route 53)
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  count                     = var.create_acm_certificate && length(var.acm_domain_names) > 0 ? 1 : 0
  domain_name               = var.acm_domain_names[0]
  subject_alternative_names = slice(var.acm_domain_names, 1, length(var.acm_domain_names))
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = var.create_acm_certificate && length(var.acm_domain_names) > 0 && local.zone_id != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  count                   = var.create_acm_certificate && length(var.acm_domain_names) > 0 && local.zone_id != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# -----------------------------------------------------------------------------
# SES
# -----------------------------------------------------------------------------

module "ses" {
  source = "../../modules/ses"
  count  = var.domain_name != "" ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  tags         = var.tags
}

module "cognito" {
  source = "../../modules/cognito"

  project_name   = var.project_name
  environment    = var.environment
  callback_urls  = var.cognito_callback_urls
  logout_urls    = var.cognito_logout_urls
  ses_from_email = var.domain_name != "" ? "noreply@${var.domain_name}" : ""
  ses_source_arn = var.domain_name != "" ? module.ses[0].domain_identity_arn : ""
  tags           = var.tags
}
