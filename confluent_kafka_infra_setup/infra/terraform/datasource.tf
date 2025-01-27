##### Data Source #####

data "aws_caller_identity" "account" {}
data "aws_region" "current" {}
data "aws_vpc" "current_vpc" {}

data "aws_subnets" "subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.current_vpc.id]
  }
}

data "aws_acm_certificate" "issued" {
  count    = var.https_enabled_ui == true ? 1 : 0
  domain   = var.acm_cert_domain_name
  statuses = ["ISSUED"]
  most_recent      = true
}