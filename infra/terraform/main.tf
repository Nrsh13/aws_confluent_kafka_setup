provider "aws" {
  profile = "default"
  region = "${var.aws_region}"  
}

terraform {
  # Providers
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  # tf version
  required_version = ">= 0.14.9"

  # Backend - Will come through Jenkins or setup_env.sh
  backend "s3" {}
}
