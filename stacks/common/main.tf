module "vpc" {
  source = "../../modules/vpc"

  project_name     = var.project_name
  environment      = var.environment
  enable_flow_logs = var.enable_vpc_flow_logs
  tags             = var.tags
}

module "cdn" {
  source = "../../modules/s3-cloudfront"
  count  = var.enable_cdn ? 1 : 0

  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.cdn_domain_name
  acm_certificate_arn = var.cdn_acm_certificate_arn
  tags                = var.tags
}

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
