# Terraform configuration for conference room booking microservices
# Implements blue-green deployment architecture with shared databases

terraform {
  required_version = ">= 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.26.0"
    }
  }

  # Remote state stored in S3 with encryption and locking
  backend "s3" {
    bucket       = "timclarke-terraform-state"
    key          = "boardroomCollective/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-2"
}
