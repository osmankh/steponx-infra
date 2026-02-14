terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  use_ses = var.ses_source_arn != ""

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

# ------------------------------------------------------------------------------
# Cognito User Pool
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool" "this" {
  name = "${local.name_prefix}-user-pool"

  # Sign-in configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = var.password_min_length
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration
  dynamic "email_configuration" {
    for_each = local.use_ses ? [1] : []

    content {
      email_sending_account = "DEVELOPER"
      from_email_address    = var.ses_from_email
      source_arn            = var.ses_source_arn
    }
  }

  dynamic "email_configuration" {
    for_each = local.use_ses ? [] : [1]

    content {
      email_sending_account = "COGNITO_DEFAULT"
    }
  }

  # Schema attributes
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  schema {
    name                     = "phone_number"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 0
      max_length = 20
    }
  }

  # MFA configuration (OPTIONAL for future phone OTP)
  mfa_configuration = "OPTIONAL"

  software_token_mfa_configuration {
    enabled = true
  }

  # Advanced security mode
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Lambda triggers (conditionally set for custom auth challenge / OTP flow)
  dynamic "lambda_config" {
    for_each = (
      var.define_auth_challenge_lambda_arn != "" &&
      var.create_auth_challenge_lambda_arn != "" &&
      var.verify_auth_challenge_response_lambda_arn != ""
    ) ? [1] : []

    content {
      define_auth_challenge          = var.define_auth_challenge_lambda_arn
      create_auth_challenge          = var.create_auth_challenge_lambda_arn
      verify_auth_challenge_response = var.verify_auth_challenge_response_lambda_arn
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-user-pool"
  })
}

# ------------------------------------------------------------------------------
# User Pool Client
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "this" {
  name         = "${local.name_prefix}-client"
  user_pool_id = aws_cognito_user_pool.this.id

  # Public client for web (no secret)
  generate_secret = false

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH",
  ]

  # Identity providers
  supported_identity_providers = ["COGNITO"]

  # Token validity
  access_token_validity  = 1
  refresh_token_validity = 30
  id_token_validity      = 1

  token_validity_units {
    access_token  = "hours"
    refresh_token = "days"
    id_token      = "hours"
  }

  # Callback and logout URLs
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Security settings
  prevent_user_existence_errors = "ENABLED"
}

# ------------------------------------------------------------------------------
# User Pool Domain (Cognito hosted)
# ------------------------------------------------------------------------------

resource "aws_cognito_user_pool_domain" "this" {
  domain       = local.name_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
