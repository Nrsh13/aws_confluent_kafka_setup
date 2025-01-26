#!/bin/bash

SSH_DIR="$HOME/.ssh"
PEM_FILE="$SSH_DIR/id_rsa"
PUB_FILE="$SSH_DIR/id_rsa.pub"

echo "\ninfo: Setting up ssh keys for Ec2 keypair for ssh to EC2s"

# Ensure the .ssh directory exists
if [ ! -d "$SSH_DIR" ]; then
  echo "\ninfo: .ssh directory does not exist. Creating it."
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
fi

# Check if the PEM and PUB files exist
if [ -f "$PEM_FILE" ] && [ -f "$PUB_FILE" ]; then
  echo "\ninfo: SSH key pair already exists at $SSH_DIR. Skipping generation."
else
  echo "\ninfo: Generating SSH keys for Ansible passwordless SSH."
  ssh-keygen -b 2048 -t rsa -f "$PEM_FILE" -q -C "ansible" -N ""
  chmod 600 "$PEM_FILE"
  chmod 644 "$PUB_FILE"
  echo "\ninfo: SSH keys generated successfully."
fi

echo "\ninfo: Update teraform.auto.tfvars with ansible user Public Key"
echo "keypair_public_key = <<-EOF" > tmp.txt
cat $PUB_FILE >> tmp.txt
echo EOF >> tmp.txt
sed -i '' '/keypair_public_key/d' ../infra/terraform/terraform.auto.tfvars
sed -i '' '/ssh-rsa/d' ../infra/terraform/terraform.auto.tfvars
sed -i '' '/EOF/d' ../infra/terraform/terraform.auto.tfvars

cat tmp.txt >> ../infra/terraform/terraform.auto.tfvars
rm -f tmp.txt

echo "\ninfo: Ansible user SSH Keys are stored in $PEM_FILE and $PUB_FILE. Will be used for SSH like below"

echo "\ninfo: ssh ansible@PUBLIC_IP_OF_EC2_INSTANCE\n"
