environment   = "production"
desired_count = 2
min_capacity  = 1
max_capacity  = 4

api_desired_count = 1
api_min_capacity  = 1
api_max_capacity  = 4

# ALB & DNS
enable_load_balancer = true
domain_name          = "steponx.com"
api_host_header      = "api.steponx.com"
create_dns_records   = true
