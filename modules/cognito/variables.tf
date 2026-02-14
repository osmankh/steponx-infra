variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)"
  type        = string
}

variable "ses_from_email" {
  description = "Email address to use as the FROM address for Cognito emails (e.g. no-reply@steponx.com)"
  type        = string
  default     = ""
}

variable "ses_source_arn" {
  description = "ARN of the SES verified identity to use for sending emails. If empty, Cognito default email is used"
  type        = string
  default     = ""
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the user pool client"
  type        = list(string)
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the user pool client"
  type        = list(string)
}

variable "password_min_length" {
  description = "Minimum length for user passwords"
  type        = number
  default     = 8
}

variable "define_auth_challenge_lambda_arn" {
  description = "ARN of the Lambda function for the DefineAuthChallenge trigger (for custom OTP flow)"
  type        = string
  default     = ""
}

variable "create_auth_challenge_lambda_arn" {
  description = "ARN of the Lambda function for the CreateAuthChallenge trigger (for custom OTP flow)"
  type        = string
  default     = ""
}

variable "verify_auth_challenge_response_lambda_arn" {
  description = "ARN of the Lambda function for the VerifyAuthChallengeResponse trigger (for custom OTP flow)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
