##### Resources #####

# EC2 Server SG
resource "aws_security_group" "ec2_server_sg" {
  name          = "${var.environment}-${var.instance}-${var.component}ServerSG"
  description   = "The security group for the ${var.component} Server"
  vpc_id        = "${var.vpc_id}"
  tags          = "${var.common_tags}"

  # Egress
  egress {
    description = "SSH with in VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = "${var.vpc_cidr}"
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
    cidr_blocks = "${var.vpc_cidr}"
  }

  ingress {
    description = "Open to World - Download Packages Requirment"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}