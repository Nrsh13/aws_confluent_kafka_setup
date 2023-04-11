# AWS Kafka Infra Setup
## Description

This project builds N EC2 instances for Kafka Cluster

## Pre-requisites
- Update aws_kafka_infra_setup/scripts/set_env.sh with your AWS Account Details.
- Generate SSH Keys for EC2 Keypair -
```
$ sh prereq-setup.sh

INFO: Generate SSH Keys for ansible password less SSH

INFO: Copy SSH Keys to ~/.ssh/ - To Allow SSH to EC2 from local

INFO: Copy SSH Keys to /root/.ssh - To Allow SSH to EC2 from Bastion

INFO: Update teraform.auto.tfvars with ansible user Public Key

INFO: Ansible user SSH Keys are ansible.pem and ansible.pem.pub. Will be used for SSH like below

INFO: ssh ansible@PUBLIC_IP_OF_EC2_INSTANCE
```
- Update aws_kafka_infra_setup/infra/terraform/terraform.auto.tfvars with required variables. keypair_public_key variable is already updated with ansible.pem.pu in previous step.

## How to Run 
```
cd aws_kafka_infra_setup/scripts

# S3 Backend
sh provision.sh -h
sh provision.sh --instance lab01 --action apply

# Remote Backend (Terraform Cloud)
- Update aws_kafka_infra_setup/infra/terraform/main.tf.remote with your Org details
- Uncomment instance variable value in aws_kafka_infra_setup/infra/terraform/terraform.auto.tfvars
terraform login
sh remote_provision.sh plan|apply|destroy
```

## Post Set up - On All EC2s
- Update Bastion Ec2 /etc/hosts with aws_kafka_infra_setup/scripts/etchosts_forBastion file content and /c/Windows/System32/drivers/etc/hosts with aws_kafka_infra_setup/scripts/etchosts_forWindows file content.
```
ssh -i "ansible.pem" ec2-user@ec2-54-206-93-240.ap-southeast-2.compute.amazonaws.com
sudo su -
vi /etc/hosts and add similar to below from aws_kafka_infra_setup/scripts/etchosts_forBastion.
172.31.15.39	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01
172.31.15.40	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01
```

## Contact
nrsh13@gmail.com
