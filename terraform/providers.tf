terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
    region = "us-east-1"
    shared_credentials_files = ["/home/joel/.aws/credentials"]
}
