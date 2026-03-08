# -----------------------------------------------------------------------------
# Remote State: Common Stack
# -----------------------------------------------------------------------------

data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = "steponx-terraform-state"
    key    = "${var.environment}/common/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  common = data.terraform_remote_state.common.outputs

  route53_zone_id     = try(local.common.route53_zone_id, "")
  acm_certificate_arn = try(local.common.acm_certificate_arn, "")

  node_env = var.environment == "production" ? "production" : "development"

  app_env_vars = merge({
    NODE_ENV             = local.node_env
    AWS_REGION           = var.aws_region
    COGNITO_USER_POOL_ID = local.common.cognito_user_pool_id
    COGNITO_CLIENT_ID    = local.common.cognito_user_pool_client_id
    MEDIA_BUCKET         = try(local.common.media_bucket_name, "")
    MEDIA_URL            = try(local.common.media_base_url, "")
  }, var.app_environment_variables)

  api_env_vars = merge({
    NODE_ENV             = local.node_env
    AWS_REGION           = var.aws_region
    COGNITO_USER_POOL_ID = local.common.cognito_user_pool_id
    COGNITO_CLIENT_ID    = local.common.cognito_user_pool_client_id
    MEDIA_BUCKET         = try(local.common.media_bucket_name, "")
    MEDIA_URL            = try(local.common.media_base_url, "")
    PORT                 = tostring(var.api_container_port)
    CUSTOM_AUTH_SECRET   = var.custom_auth_secret
    AUTH_SECRET          = var.auth_secret
  }, var.api_environment_variables)
}

# -----------------------------------------------------------------------------
# ECS Tasks Security Group (created here to break module dependency)
# -----------------------------------------------------------------------------
# The ECS service module creates its own SG, but we also need a reference
# before the service is created so RDS can allow inbound from ECS tasks.

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-tasks-"
  description = "Security group for ECS tasks"
  vpc_id      = local.common.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ecs-tasks"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow inbound from ALB to ECS tasks on the web container port
resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  count = var.enable_load_balancer ? 1 : 0

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = module.alb[0].security_group_id
  description              = "Allow inbound from ALB on web port"
}

# Allow inbound from ALB to ECS tasks on the API container port
resource "aws_security_group_rule" "ecs_ingress_from_alb_api" {
  count = var.enable_load_balancer ? 1 : 0

  type                     = "ingress"
  from_port                = var.api_container_port
  to_port                  = var.api_container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = module.alb[0].security_group_id
  description              = "Allow inbound from ALB on API port"
}

# -----------------------------------------------------------------------------
# ECR Repositories
# -----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

module "ecr_api" {
  source = "../../modules/ecr"

  project_name    = var.project_name
  environment     = var.environment
  repository_name = "${var.project_name}-${var.environment}-api"
  tags            = var.tags
}

# -----------------------------------------------------------------------------
# ECS Cluster
# -----------------------------------------------------------------------------

module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# -----------------------------------------------------------------------------
# Application Load Balancer
# -----------------------------------------------------------------------------

module "alb" {
  source = "../../modules/alb"
  count  = var.enable_load_balancer ? 1 : 0

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = local.common.vpc_id
  public_subnet_ids = local.common.public_subnet_ids
  certificate_arn   = local.acm_certificate_arn
  tags              = var.tags
}

# -----------------------------------------------------------------------------
# API Target Group & Listener Rules
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "api" {
  count = var.enable_load_balancer ? 1 : 0

  name        = "${var.project_name}-${var.environment}-api-tg"
  port        = var.api_container_port
  protocol    = "HTTP"
  vpc_id      = local.common.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-tg"
  })
}

# API host-based routing on HTTPS listener
resource "aws_lb_listener_rule" "api_host_https" {
  count = var.enable_load_balancer && var.api_host_header != "" && local.acm_certificate_arn != "" ? 1 : 0

  listener_arn = module.alb[0].https_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }

  condition {
    host_header {
      values = [var.api_host_header]
    }
  }
}

# API host-based routing on HTTP listener (when no certificate)
resource "aws_lb_listener_rule" "api_host_http" {
  count = var.enable_load_balancer && var.api_host_header != "" && local.acm_certificate_arn == "" ? 1 : 0

  listener_arn = module.alb[0].http_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }

  condition {
    host_header {
      values = [var.api_host_header]
    }
  }
}

# -----------------------------------------------------------------------------
# RDS PostgreSQL
# -----------------------------------------------------------------------------

module "rds" {
  source = "../../modules/rds"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = local.common.vpc_id
  private_subnet_ids         = local.common.private_subnet_ids
  allowed_security_group_ids = [aws_security_group.ecs_tasks.id]
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  multi_az                   = var.db_multi_az
  tags                       = var.tags
}

# -----------------------------------------------------------------------------
# ECS Service — Web (Next.js)
# -----------------------------------------------------------------------------

module "ecs_service" {
  source = "../../modules/ecs-service"

  project_name          = var.project_name
  environment           = var.environment
  service_name          = "web"
  cluster_id            = module.ecs_cluster.cluster_id
  task_family           = "${var.project_name}-${var.environment}"
  container_image       = var.container_image != "" ? var.container_image : "${module.ecr.repository_url}:latest"
  container_port        = var.container_port
  cpu                   = var.cpu
  memory                = var.memory
  desired_count         = var.desired_count
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  target_group_arn      = var.enable_load_balancer ? module.alb[0].target_group_arn : ""
  subnet_ids            = local.common.public_subnet_ids
  assign_public_ip      = true
  vpc_id                = local.common.vpc_id
  vpc_cidr              = local.common.vpc_cidr_block
  enable_alb_ingress    = var.enable_load_balancer
  alb_security_group_id = var.enable_load_balancer ? module.alb[0].security_group_id : ""

  health_check_command = ["CMD-SHELL", "node -e \"const http=require('http');http.get('http://localhost:${var.container_port}/api/health',(r)=>{process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))\""]

  environment_variables = local.app_env_vars

  secrets = {
    DATABASE_SECRET = module.rds.db_secret_arn
  }

  tags = var.tags
}

# Allow web ECS service SG to access RDS
resource "aws_security_group_rule" "rds_ingress_from_ecs_service" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.ecs_service.security_group_id
  description              = "Allow PostgreSQL from web ECS service tasks"
}

# -----------------------------------------------------------------------------
# ECS Service — API (Fastify + tRPC)
# -----------------------------------------------------------------------------

module "ecs_service_api" {
  source = "../../modules/ecs-service"

  project_name          = var.project_name
  environment           = var.environment
  service_name          = "api"
  cluster_id            = module.ecs_cluster.cluster_id
  task_family           = "${var.project_name}-${var.environment}-api"
  container_image       = var.api_container_image != "" ? var.api_container_image : "${module.ecr_api.repository_url}:latest"
  container_port        = var.api_container_port
  cpu                   = var.api_cpu
  memory                = var.api_memory
  desired_count         = var.api_desired_count
  min_capacity          = var.api_min_capacity
  max_capacity          = var.api_max_capacity
  target_group_arn      = var.enable_load_balancer ? aws_lb_target_group.api[0].arn : ""
  subnet_ids            = local.common.public_subnet_ids
  assign_public_ip      = true
  vpc_id                = local.common.vpc_id
  vpc_cidr              = local.common.vpc_cidr_block
  enable_alb_ingress    = var.enable_load_balancer
  alb_security_group_id = var.enable_load_balancer ? module.alb[0].security_group_id : ""

  health_check_command = ["CMD-SHELL", "node -e \"const http=require('http');http.get('http://localhost:${var.api_container_port}/health',(r)=>{process.exit(r.statusCode===200?0:1)}).on('error',()=>process.exit(1))\""]

  environment_variables = local.api_env_vars

  secrets = {
    DATABASE_SECRET = module.rds.db_secret_arn
  }

  tags = var.tags
}

# Allow API ECS service SG to access RDS
resource "aws_security_group_rule" "rds_ingress_from_ecs_service_api" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.ecs_service_api.security_group_id
  description              = "Allow PostgreSQL from API ECS service tasks"
}

# -----------------------------------------------------------------------------
# Route 53 DNS Records
# -----------------------------------------------------------------------------

resource "aws_route53_record" "web" {
  count   = var.create_dns_records && var.enable_load_balancer && var.domain_name != "" && local.route53_zone_id != "" ? 1 : 0
  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb[0].alb_dns_name
    zone_id                = module.alb[0].alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  count   = var.create_dns_records && var.enable_load_balancer && var.api_host_header != "" && local.route53_zone_id != "" ? 1 : 0
  zone_id = local.route53_zone_id
  name    = var.api_host_header
  type    = "A"

  alias {
    name                   = module.alb[0].alb_dns_name
    zone_id                = module.alb[0].alb_zone_id
    evaluate_target_health = true
  }
}
