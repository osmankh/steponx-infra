variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. staging, production)"
  type        = string
}

variable "custom_auth_secret" {
  description = "Shared secret used by CreateAuthChallenge and VerifyAuthChallengeResponse Lambdas for HMAC computation"
  type        = string
  sensitive   = true
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool that will invoke these Lambda triggers"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
