environment   = "dev"
desired_count = 1
min_capacity  = 1
max_capacity  = 2
cpu           = 256
memory        = 512

api_desired_count = 1
api_min_capacity  = 1
api_max_capacity  = 2
api_cpu           = 256
api_memory        = 512

# ALB & DNS
enable_load_balancer = true
domain_name          = "dev.steponx.com"
api_host_header      = "api.dev.steponx.com"
create_dns_records   = true
