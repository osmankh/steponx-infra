###############################################################################
# Terraform State — S3 Bucket
###############################################################################

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"

  tags = merge(var.tags, {
    Name = "${var.project_name}-terraform-state"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################################
# Terraform State — DynamoDB Lock Table
###############################################################################

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-terraform-locks"
  })
}

###############################################################################
# GitHub Actions OIDC Provider
###############################################################################

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-oidc"
  })
}

###############################################################################
# GitHub Actions IAM Role (OIDC Federation)
###############################################################################

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-actions"
  })
}

###############################################################################
# GitHub Actions IAM Policy
###############################################################################

data "aws_iam_policy_document" "github_actions_permissions" {
  # EC2 / VPC — full
  statement {
    sid    = "EC2VPCFull"
    effect = "Allow"
    actions = [
      "ec2:*",
    ]
    resources = ["*"]
  }

  # ECS — full
  statement {
    sid    = "ECSFull"
    effect = "Allow"
    actions = [
      "ecs:*",
    ]
    resources = ["*"]
  }

  # ECR — full
  statement {
    sid    = "ECRFull"
    effect = "Allow"
    actions = [
      "ecr:*",
    ]
    resources = ["*"]
  }

  # RDS — full
  statement {
    sid    = "RDSFull"
    effect = "Allow"
    actions = [
      "rds:*",
    ]
    resources = ["*"]
  }

  # S3 — full
  statement {
    sid    = "S3Full"
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = ["*"]
  }

  # CloudFront — full
  statement {
    sid    = "CloudFrontFull"
    effect = "Allow"
    actions = [
      "cloudfront:*",
    ]
    resources = ["*"]
  }

  # SES — full
  statement {
    sid    = "SESFull"
    effect = "Allow"
    actions = [
      "ses:*",
    ]
    resources = ["*"]
  }

  # Cognito — full
  statement {
    sid    = "CognitoFull"
    effect = "Allow"
    actions = [
      "cognito-idp:*",
      "cognito-identity:*",
    ]
    resources = ["*"]
  }

  # IAM — create and manage roles and policies
  statement {
    sid    = "IAMManageRolesAndPolicies"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:UpdateRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:ListInstanceProfiles",
      "iam:ListInstanceProfilesForRole",
      "iam:CreateServiceLinkedRole",
      "iam:DeleteServiceLinkedRole",
      "iam:GetServiceLinkedRoleDeletionStatus",
    ]
    resources = ["*"]
  }

  # CloudWatch — full
  statement {
    sid    = "CloudWatchFull"
    effect = "Allow"
    actions = [
      "cloudwatch:*",
    ]
    resources = ["*"]
  }

  # Route53 — full
  statement {
    sid    = "Route53Full"
    effect = "Allow"
    actions = [
      "route53:*",
      "route53domains:*",
    ]
    resources = ["*"]
  }

  # ACM — full
  statement {
    sid    = "ACMFull"
    effect = "Allow"
    actions = [
      "acm:*",
    ]
    resources = ["*"]
  }

  # Elastic Load Balancing — full
  statement {
    sid    = "ELBFull"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*",
    ]
    resources = ["*"]
  }

  # Secrets Manager — full
  statement {
    sid    = "SecretsManagerFull"
    effect = "Allow"
    actions = [
      "secretsmanager:*",
    ]
    resources = ["*"]
  }

  # SSM — full
  statement {
    sid    = "SSMFull"
    effect = "Allow"
    actions = [
      "ssm:*",
    ]
    resources = ["*"]
  }

  # DynamoDB — read for state locking
  statement {
    sid    = "DynamoDBStateLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]
    resources = [
      aws_dynamodb_table.terraform_locks.arn,
    ]
  }

  # SNS — full
  statement {
    sid    = "SNSFull"
    effect = "Allow"
    actions = [
      "sns:*",
    ]
    resources = ["*"]
  }

  # Lambda — full (for Cognito triggers and other functions)
  statement {
    sid    = "LambdaFull"
    effect = "Allow"
    actions = [
      "lambda:*",
    ]
    resources = ["*"]
  }

  # CloudWatch Logs — full
  statement {
    sid    = "LogsFull"
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = ["*"]
  }

  # STS — GetCallerIdentity
  statement {
    sid    = "STSGetCallerIdentity"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # Application Auto Scaling — full
  statement {
    sid    = "ApplicationAutoScalingFull"
    effect = "Allow"
    actions = [
      "application-autoscaling:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_actions" {
  name        = "${var.project_name}-github-actions-policy"
  description = "Permissions for GitHub Actions to manage ${var.project_name} infrastructure"
  policy      = data.aws_iam_policy_document.github_actions_permissions.json

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-actions-policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
