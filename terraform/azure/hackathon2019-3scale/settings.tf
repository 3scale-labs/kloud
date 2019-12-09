terraform {
  required_version = "~> 0.12"
  backend "s3" {
    role_arn       = "arn:aws:iam::396994816590:role/OrganizationAccountAccessRole"
    session_name   = "terraform"
    encrypt        = true
    bucket         = "3scale-dev-tfstate"
    region         = "us-east-1"
    key            = "3scale-dev/multicloud/terraform/azure"
    dynamodb_table = "3scale-dev-tfstate-lock"
  }
}

provider "azurerm" {
  version = "=1.34.0"
}
