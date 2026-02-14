terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# -----------------------------------------------------------------------------
# IAM - Execution Role (used by ECS agent to pull images, push logs, read secrets)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "execution" {
  name = "${var.project_name}-${var.environment}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "${var.project_name}-${var.environment}-execution-secrets"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
        ]
        Resource = "*"
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# IAM - Task Role (used by the application at runtime)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "task" {
  name = "${var.project_name}-${var.environment}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "task_app" {
  name = "${var.project_name}-${var.environment}-task-app"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:ListUsers",
        ]
        Resource = "*"
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.project_name}-${var.environment}/${var.task_family}"
  retention_in_days = 30

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECS Task Definition
# -----------------------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = var.task_family
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        for name, value in var.environment_variables : {
          name  = name
          value = value
        }
      ]

      secrets = [
        for name, arn in var.secrets : {
          name      = name
          valueFrom = arn
        }
      ]
    },
  ])

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-${var.environment}-${var.task_family}-ecs"
  description = "Security group for ${var.task_family} ECS service"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${var.task_family}-ecs"
  })
}

resource "aws_security_group_rule" "ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_security_group.ecs_service.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_service.id
}

# -----------------------------------------------------------------------------
# ECS Service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "this" {
  name            = "${var.project_name}-${var.environment}-${var.task_family}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.task_family
    container_port   = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_ecs_task_definition.this]

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Auto Scaling
# -----------------------------------------------------------------------------

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${split("/", var.cluster_id)[1]}/${aws_ecs_service.this.name}"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-${var.environment}-${var.task_family}-cpu"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  resource_id        = aws_appautoscaling_target.this.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.project_name}-${var.environment}-${var.task_family}-memory"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  resource_id        = aws_appautoscaling_target.this.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
  }
}
