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
  for_each = var.create_acm_certificate && (var.create_hosted_zone || var.route53_zone_id != "") && length(var.acm_domain_names) > 0 ? toset(var.acm_domain_names) : toset([])

  zone_id         = local.zone_id
  name            = one([for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.resource_record_name if dvo.domain_name == each.key])
  type            = "CNAME"
  records         = [one([for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.resource_record_value if dvo.domain_name == each.key])]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  count                   = var.create_acm_certificate && (var.create_hosted_zone || var.route53_zone_id != "") && length(var.acm_domain_names) > 0 ? 1 : 0
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

# -----------------------------------------------------------------------------
# SES DNS Records (domain verification + DKIM)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "ses_verification" {
  count   = var.domain_name != "" && (var.create_hosted_zone || var.route53_zone_id != "") ? 1 : 0
  zone_id = local.zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = [module.ses[0].domain_verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  count   = var.domain_name != "" && (var.create_hosted_zone || var.route53_zone_id != "") ? 3 : 0
  zone_id = local.zone_id
  name    = "${module.ses[0].dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${module.ses[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# -----------------------------------------------------------------------------
# Google & DMARC DNS Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "google_verification_cname" {
  count   = var.create_hosted_zone && var.domain_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = "lyycatvgd4uv.${var.domain_name}"
  type    = "CNAME"
  ttl     = 3600
  records = ["gv-i2dtpzrupjlvhe.dv.googlehosted.com"]
}

resource "aws_route53_record" "google_verification_txt" {
  count   = var.create_hosted_zone && var.domain_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = [
    "google-site-verification=xzd621L4GoW2KhlkHJhqryCmy5YeD7QS2k8SXJz-dlo",
  ]
}

resource "aws_route53_record" "dmarc" {
  count   = var.create_hosted_zone && var.domain_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 3600
  records = ["v=DMARC1; p=quarantine; adkim=r; aspf=r;"]
}

# CAA records — allow Amazon to issue certificates
resource "aws_route53_record" "caa" {
  count   = var.create_hosted_zone && var.domain_name != "" ? 1 : 0
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "CAA"
  ttl     = 3600
  records = [
    "0 issue \"amazon.com\"",
    "0 issuewild \"amazon.com\"",
  ]
}

# -----------------------------------------------------------------------------
# Cognito
# -----------------------------------------------------------------------------

module "cognito_triggers" {
  source = "../../modules/cognito-triggers"

  project_name          = var.project_name
  environment           = var.environment
  custom_auth_secret    = var.custom_auth_secret
  cognito_user_pool_arn = module.cognito.user_pool_arn
  tags                  = var.tags
}

module "cognito" {
  source = "../../modules/cognito"

  project_name   = var.project_name
  environment    = var.environment
  callback_urls  = var.cognito_callback_urls
  logout_urls    = var.cognito_logout_urls
  ses_from_email = var.domain_name != "" ? "noreply@${var.domain_name}" : ""
  ses_source_arn = var.domain_name != "" ? module.ses[0].domain_identity_arn : ""

  define_auth_challenge_lambda_arn          = module.cognito_triggers.define_auth_challenge_lambda_arn
  create_auth_challenge_lambda_arn          = module.cognito_triggers.create_auth_challenge_lambda_arn
  verify_auth_challenge_response_lambda_arn = module.cognito_triggers.verify_auth_challenge_response_lambda_arn

  tags = var.tags
}
