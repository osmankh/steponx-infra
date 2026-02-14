terraform {
  backend "s3" {
    bucket         = "steponx-terraform-state"
    key            = "common/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "steponx-terraform-locks"
    encrypt        = true
  }
}
