environment         = "production"
domain_name         = "steponx.com"
enable_media_bucket = true

# DNS & SSL
create_hosted_zone     = true
create_acm_certificate = true
acm_domain_names       = ["steponx.com", "*.steponx.com"]
