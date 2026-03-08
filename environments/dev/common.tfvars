environment         = "dev"
enable_media_bucket = true

# DNS & SSL — zone created in production, referenced here by ID
create_hosted_zone     = false
route53_zone_id        = "Z0635708S9DARVY9Z2AY"
create_acm_certificate = true
acm_domain_names       = ["dev.steponx.com", "*.dev.steponx.com"]
