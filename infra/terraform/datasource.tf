##### Data Source #####
data "aws_subnet_ids" "subnet_ids" {
  vpc_id = "${var.vpc_id}"
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