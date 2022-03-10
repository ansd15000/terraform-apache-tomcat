provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=3.6.0"
    }
  }
  backend "s3" { # S3 및 DynamoDB는 미리 생성되있어야함.
    bucket = "ash-testing"
    key = "terraform/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform_state_lock"
  }
}