##### Resources #####

# EC2 Server SG
resource "aws_security_group" "ec2_server_sg" {
  name          = "${var.project}-${var.environment}-${var.component}ServerSG"
  description   = "The security group for the ${var.component} Server"
  vpc_id        = "${data.aws_vpc.current_vpc.id}"
  tags          = "${var.common_tags}"

  # Egress
  egress {
    description = "SSH with in VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${data.aws_vpc.current_vpc.cidr_block}"]
  }

  egress {
    description = "Open to World - Download Packages Requirment"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # Ingress
  ingress {
    description = "SSH with in VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${data.aws_vpc.current_vpc.cidr_block}"]
  }

  ingress {
    description = "Open to World - Download Packages Requirment"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}