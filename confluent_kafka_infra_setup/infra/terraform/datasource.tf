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

# Render EC2 userdata
data "template_file" "ec2_userdata" {
template = "${file("./userdata.sh")}"
vars = {
    aws_region = "${var.aws_region}"
    public_key = "${var.keypair_public_key}"
    passwordless_ssh_user = "${var.passwordless_ssh_user}"
  }
}
