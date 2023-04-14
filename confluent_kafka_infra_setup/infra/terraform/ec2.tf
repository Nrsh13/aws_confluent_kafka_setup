##### Resources #####

## Attach pre-generated keypair to instance - ssh-keygen -C userName
resource "aws_key_pair" "ec2-key" {
  key_name    = "${var.passwordless_ssh_user}"
  public_key  = "${var.keypair_public_key}"
}

## EC2s
resource "aws_instance" "my_ec2_instances" {
  count = "${var.instance_count}"
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${var.environment}-${var.instance}-${var.component}EC2RoleInstanceProfile"
  tags = merge(var.common_tags,var.specific_tags, {"Name"="${var.component}-${var.instance}-0${count.index + 1}"})
  #subnet_id = element(sort(data.aws_subnet_ids.subnet_ids.ids), 0)
  subnet_id = element(sort(data.aws_subnets.subnet_ids.ids), "${count.index + 1}")
  vpc_security_group_ids = ["${aws_security_group.ec2_server_sg.id}"]
  key_name  = aws_key_pair.ec2-key.key_name
  user_data = "${data.template_file.ec2_userdata.rendered}"
  #/dev/sda1
  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = false
  }

  lifecycle {
    ignore_changes = [ami]
  }

  # To set EC2 hostname, /etc/hosts and Cloud Init completion status
  connection {
    type     = "ssh"
    user     = "ansible"
    private_key = "${file("../../scripts/ansible.pem")}"
    host     = "${self.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      # "sudo -s bash -c \"hostnamectl set-hostname ${var.component}-${var.instance}-0${count.index + 1}${var.hostname_domain}\"",
      "sleep 120", #wait for 2 mins and then check userdata status using cloud-init
      "cloud-init status --wait"
    ]
  }
}

# To set up ssh to all Ec2s from Local
resource "null_resource" "ansible" {
  depends_on = [
    aws_instance.my_ec2_instances
  ]

  triggers = {
    key = "${uuid()}"
  }

  provisioner "local-exec" {
    #  interpreter = ["PowerShell", "-Command"]
    interpreter = [
      "bash" , "-c"
    ]
    command = <<-EOT
      sh ../../scripts/post-setup.sh ${var.component} ${var.instance}  ${var.instance_count} ${var.hostname_domain} ${var.passwordless_ssh_user}
    EOT
  }

}

###### Output ######
output "ETC_HOSTS_DETAILS" {
  description = "Details for /etc/hosts"
  value = "Refer scripts/etchostsBastion and scripts/etchostsWindows file for update(if needed) /etc/hosts or /c/Windows/System32/drivers/etc/hosts."
}

output "Private_IP" {
  description = "List of private IP addresses assigned to the instances"
  value = aws_instance.my_ec2_instances.*.private_ip
}

output "Public_IP" {
  description = "List of Public IP addresses assigned to the instances"
  value = aws_instance.my_ec2_instances.*.public_ip
}
