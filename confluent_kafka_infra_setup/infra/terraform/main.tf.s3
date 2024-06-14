# Configure the AWS Provider
provider "aws" {
  region     = var.aws_region
  profile    = "default"
  # access_key = "yourAccessKey"
  # secret_key = "YourSecretKey"
  # assume_role {
  #   role_arn = "arn:aws:iam::${data.aws_caller_identity.account.id}:role/TerraformRole"
  # }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  # tf version
  required_version = ">= 0.14.9"

  # S3 Backend - Keys are independent of provider settings
  # bucket, key and region - passing through command line in provision.sh
  backend "s3" {
    profile = "default"
  }

}



