terraform {
  backend "s3" {
    bucket         = "steponx-terraform-state"
    key            = "backend/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "steponx-terraform-locks"
    encrypt        = true
  }
}
