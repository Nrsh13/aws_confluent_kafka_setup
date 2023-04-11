# Configure the AWS Provider
provider "aws" {
  region     = var.aws_region
}

terraform {
  backend "remote" {
    organization = "NRSH13_AWS"

    workspaces {
      name = "aws_kafka_infra_setup"
    }
  }
}
