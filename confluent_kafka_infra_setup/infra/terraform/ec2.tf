##### Resources #####

locals {
  ec2_userdata =  templatefile("./userdata.sh", {
    aws_region = "${var.aws_region}"
    public_key = "${var.keypair_public_key}"
    passwordless_ssh_user = "${var.passwordless_ssh_user}"
  })
}

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
  iam_instance_profile = "${var.project}-${var.environment}-${var.component}EC2RoleInstanceProfile"
  tags = merge(var.common_tags,var.specific_tags, {"Name"="${var.component}-${var.environment}-0${count.index + 1}"})
  #subnet_id = element(sort(data.aws_subnet_ids.subnet_ids.ids), 0)
  subnet_id = element(sort(data.aws_subnets.subnet_ids.ids), "${count.index + 1}")
  vpc_security_group_ids = ["${aws_security_group.ec2_server_sg.id}"]
  key_name  = aws_key_pair.ec2-key.key_name
  user_data = local.ec2_userdata
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
    private_key = file(var.ssh_private_key_file_location)
    host     = "${self.public_ip}"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      # "sudo -s bash -c \"hostnamectl set-hostname ${var.component}-${var.environment}-0${count.index + 1}${var.hostname_domain}\"",
      "sleep 120", #wait for 2 mins and then check userdata status using cloud-init
      "cloud-init status --wait"
    ]
  }
}


resource "null_resource" "ansible" {
  depends_on = [
    aws_instance.my_ec2_instances
  ]

  triggers = {
    # Trigger the resource if the flag file does not exist or if it's not present
    setup_done = fileexists("../../scripts/ssh_setup_done.flag") ? "true" : "false"
  }

  provisioner "local-exec" {
    interpreter = [
      "bash", "-c"
    ]
    command = <<-EOT
      # Check if the flag file does not exist, meaning the setup is not done
      if [ ! -f "../../scripts/ssh_setup_done.flag" ]; then
        echo "INFO: Running SSH setup for the first time"
        
        # Run the setup script
        sh ../../scripts/post-setup-etc-hosts.sh ${var.component} ${var.environment} ${var.instance_count} ${var.hostname_domain} ${var.passwordless_ssh_user}
        
        # Create the flag file to mark the setup as done
        touch ../../scripts/ssh_setup_done.flag
      else
        echo "INFO: SSH setup has already been done, skipping."
      fi
    EOT
  }
}
