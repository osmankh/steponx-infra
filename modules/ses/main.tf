terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
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

  from_address = "noreply@${var.domain_name}"
  name_prefix  = "${var.project_name}-${var.environment}"
}

# ------------------------------------------------------------------------------
# SES Domain Identity
# ------------------------------------------------------------------------------

resource "aws_ses_domain_identity" "this" {
  domain = var.domain_name
}

# ------------------------------------------------------------------------------
# SES Domain DKIM
# Generates DKIM tokens. The corresponding CNAME records must be added to DNS
# manually (or via a separate Route53 module) to complete DKIM verification.
# ------------------------------------------------------------------------------

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

# ------------------------------------------------------------------------------
# SES Email Identity (from address)
# ------------------------------------------------------------------------------

resource "aws_ses_email_identity" "noreply" {
  email = local.from_address
}

# ------------------------------------------------------------------------------
# SNS Topics for Bounce and Complaint Notifications
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "bounces" {
  name = "${local.name_prefix}-ses-bounces"
  tags = local.common_tags
}

resource "aws_sns_topic" "complaints" {
  name = "${local.name_prefix}-ses-complaints"
  tags = local.common_tags
}

# ------------------------------------------------------------------------------
# SNS Topic Policies - Allow SES to publish to the topics
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "sns_ses_publish" {
  statement {
    sid    = "AllowSESPublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_ses_domain_identity.this.arn]
    }
  }
}

resource "aws_sns_topic_policy" "bounces" {
  arn    = aws_sns_topic.bounces.arn
  policy = data.aws_iam_policy_document.sns_ses_publish.json
}

resource "aws_sns_topic_policy" "complaints" {
  arn    = aws_sns_topic.complaints.arn
  policy = data.aws_iam_policy_document.sns_ses_publish.json
}

# ------------------------------------------------------------------------------
# SES Configuration Set
# ------------------------------------------------------------------------------

resource "aws_ses_configuration_set" "this" {
  name = "${local.name_prefix}-config-set"

  delivery_options {
    tls_policy = "Require"
  }
}

# ------------------------------------------------------------------------------
# SES Event Destinations - Route bounce and complaint events to SNS
# ------------------------------------------------------------------------------

resource "aws_ses_event_destination" "bounces" {
  name                   = "${local.name_prefix}-bounce-events"
  configuration_set_name = aws_ses_configuration_set.this.name
  enabled                = true
  matching_types         = ["bounce"]

  sns_destination {
    topic_arn = aws_sns_topic.bounces.arn
  }
}

resource "aws_ses_event_destination" "complaints" {
  name                   = "${local.name_prefix}-complaint-events"
  configuration_set_name = aws_ses_configuration_set.this.name
  enabled                = true
  matching_types         = ["complaint"]

  sns_destination {
    topic_arn = aws_sns_topic.complaints.arn
  }
}

# ------------------------------------------------------------------------------
# SES Identity Notification Topics (domain-level bounce/complaint forwarding)
# ------------------------------------------------------------------------------

resource "aws_ses_identity_notification_topic" "bounces" {
  topic_arn                = aws_sns_topic.bounces.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "complaints" {
  topic_arn                = aws_sns_topic.complaints.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.this.domain
  include_original_headers = true
}

# ------------------------------------------------------------------------------
# IAM Policy for Sending Email (to be attached to ECS task role)
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "ses_send" {
  statement {
    sid    = "AllowSESSendEmail"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
      "ses:SendTemplatedEmail",
      "ses:SendBulkTemplatedEmail",
    ]

    resources = [
      aws_ses_domain_identity.this.arn,
      aws_ses_configuration_set.this.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [local.from_address]
    }
  }

  statement {
    sid    = "AllowSESGetSendQuota"
    effect = "Allow"

    actions = [
      "ses:GetSendQuota",
      "ses:GetSendStatistics",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ses_send" {
  name        = "${local.name_prefix}-ses-send"
  description = "Allows sending email via SES for ${var.project_name} ${var.environment}"
  policy      = data.aws_iam_policy_document.ses_send.json

  tags = local.common_tags
}
