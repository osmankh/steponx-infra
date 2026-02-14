# -----------------------------------------------------------------------------
# Remote State: Common Stack
# -----------------------------------------------------------------------------

data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket = "steponx-terraform-state"
    key    = "common/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  common = data.terraform_remote_state.common.outputs

  app_env_vars = merge({
    NODE_ENV             = "production"
    DATABASE_URL         = "" # Populated from secrets at runtime
    AWS_REGION           = var.aws_region
    COGNITO_USER_POOL_ID = local.common.cognito_user_pool_id
    COGNITO_CLIENT_ID    = local.common.cognito_user_pool_client_id
    CDN_DOMAIN           = local.common.cdn_domain_name
    NEXT_PUBLIC_CDN_URL  = local.common.cdn_domain_name != "" ? "https://${local.common.cdn_domain_name}" : ""
  }, var.app_environment_variables)
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

# Allow inbound from ALB to ECS tasks on the container port
resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  count = var.enable_load_balancer ? 1 : 0

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = module.alb[0].security_group_id
  description              = "Allow inbound from ALB"
}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
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
  certificate_arn   = var.alb_certificate_arn
  tags              = var.tags
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
# ECS Service (Next.js Application)
# -----------------------------------------------------------------------------

module "ecs_service" {
  source = "../../modules/ecs-service"

  project_name          = var.project_name
  environment           = var.environment
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
  private_subnet_ids    = local.common.private_subnet_ids
  vpc_id                = local.common.vpc_id
  alb_security_group_id = var.enable_load_balancer ? module.alb[0].security_group_id : ""

  environment_variables = local.app_env_vars

  secrets = {
    DATABASE_SECRET = module.rds.db_secret_arn
  }

  tags = var.tags
}

# Allow ECS service's own SG to also access RDS (in addition to the stack SG)
resource "aws_security_group_rule" "rds_ingress_from_ecs_service" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.db_security_group_id
  source_security_group_id = module.ecs_service.security_group_id
  description              = "Allow PostgreSQL from ECS service tasks"
}
