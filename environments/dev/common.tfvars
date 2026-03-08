environment         = "dev"
enable_media_bucket = true

# DNS & SSL — zone is looked up (created in production)
create_hosted_zone     = false
create_acm_certificate = true
acm_domain_names       = ["dev.steponx.com", "*.dev.steponx.com"]
