terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )

  lambdas = {
    define_auth_challenge = {
      name        = "DefineAuthChallenge"
      source_file = "${path.module}/lambdas/define-auth-challenge.js"
      environment = {}
    }
    create_auth_challenge = {
      name        = "CreateAuthChallenge"
      source_file = "${path.module}/lambdas/create-auth-challenge.js"
      environment = {
        CUSTOM_AUTH_SECRET = var.custom_auth_secret
      }
    }
    verify_auth_challenge_response = {
      name        = "VerifyAuthChallengeResponse"
      source_file = "${path.module}/lambdas/verify-auth-challenge.js"
      environment = {
        CUSTOM_AUTH_SECRET = var.custom_auth_secret
      }
    }
  }
}

# -----------------------------------------------------------------------------
# IAM Role (shared by all three Lambdas)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-cognito-triggers-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Lambda archives
# -----------------------------------------------------------------------------

data "archive_file" "define_auth_challenge" {
  type        = "zip"
  source_file = local.lambdas.define_auth_challenge.source_file
  output_path = "${path.module}/lambdas/define-auth-challenge.zip"
}

data "archive_file" "create_auth_challenge" {
  type        = "zip"
  source_file = local.lambdas.create_auth_challenge.source_file
  output_path = "${path.module}/lambdas/create-auth-challenge.zip"
}

data "archive_file" "verify_auth_challenge_response" {
  type        = "zip"
  source_file = local.lambdas.verify_auth_challenge_response.source_file
  output_path = "${path.module}/lambdas/verify-auth-challenge.zip"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "define_auth_challenge" {
  name              = "/aws/lambda/${local.name_prefix}-DefineAuthChallenge"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "create_auth_challenge" {
  name              = "/aws/lambda/${local.name_prefix}-CreateAuthChallenge"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "verify_auth_challenge_response" {
  name              = "/aws/lambda/${local.name_prefix}-VerifyAuthChallengeResponse"
  retention_in_days = 30

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "define_auth_challenge" {
  function_name    = "${local.name_prefix}-DefineAuthChallenge"
  role             = aws_iam_role.lambda.arn
  handler          = "define-auth-challenge.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.define_auth_challenge.output_path
  source_code_hash = data.archive_file.define_auth_challenge.output_base64sha256

  depends_on = [aws_cloudwatch_log_group.define_auth_challenge]

  tags = local.common_tags
}

resource "aws_lambda_function" "create_auth_challenge" {
  function_name    = "${local.name_prefix}-CreateAuthChallenge"
  role             = aws_iam_role.lambda.arn
  handler          = "create-auth-challenge.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.create_auth_challenge.output_path
  source_code_hash = data.archive_file.create_auth_challenge.output_base64sha256

  environment {
    variables = {
      CUSTOM_AUTH_SECRET = var.custom_auth_secret
    }
  }

  depends_on = [aws_cloudwatch_log_group.create_auth_challenge]

  tags = local.common_tags
}

resource "aws_lambda_function" "verify_auth_challenge_response" {
  function_name    = "${local.name_prefix}-VerifyAuthChallengeResponse"
  role             = aws_iam_role.lambda.arn
  handler          = "verify-auth-challenge.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.verify_auth_challenge_response.output_path
  source_code_hash = data.archive_file.verify_auth_challenge_response.output_base64sha256

  environment {
    variables = {
      CUSTOM_AUTH_SECRET = var.custom_auth_secret
    }
  }

  depends_on = [aws_cloudwatch_log_group.verify_auth_challenge_response]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda Permissions (allow Cognito to invoke)
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "define_auth_challenge" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.define_auth_challenge.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.cognito_user_pool_arn
}

resource "aws_lambda_permission" "create_auth_challenge" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_auth_challenge.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.cognito_user_pool_arn
}

resource "aws_lambda_permission" "verify_auth_challenge_response" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify_auth_challenge_response.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = var.cognito_user_pool_arn
}
