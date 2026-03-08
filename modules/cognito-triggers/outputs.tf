output "define_auth_challenge_lambda_arn" {
  description = "ARN of the DefineAuthChallenge Lambda function"
  value       = aws_lambda_function.define_auth_challenge.arn
}

output "create_auth_challenge_lambda_arn" {
  description = "ARN of the CreateAuthChallenge Lambda function"
  value       = aws_lambda_function.create_auth_challenge.arn
}

output "verify_auth_challenge_response_lambda_arn" {
  description = "ARN of the VerifyAuthChallengeResponse Lambda function"
  value       = aws_lambda_function.verify_auth_challenge_response.arn
}
