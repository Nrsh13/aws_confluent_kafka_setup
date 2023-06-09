# AWS Kafka Infra Setup
## Description

This project builds N EC2 instances for Kafka Cluster

## Pre-requisites
- Update confluent_kafka_infra_setup/scripts/set_env.sh with your AWS Account Details.
- Generate SSH Keys for EC2 Keypair -
```
$ sh prereq-setup.sh

INFO: Generate SSH Keys for ansible password less SSH

INFO: Copy SSH Keys to ~/.ssh/ - To Allow SSH to EC2 from local

INFO: Copy SSH Keys to /root/.ssh - To Allow SSH to EC2 from Bastion

INFO: Update teraform.auto.tfvars with ansible user Public Key

INFO: Ansible user SSH Keys are ansible.pem and ansible.pem.pub. Will be used for SSH like below

INFO: ssh -q -o "StrictHostKeyChecking=no" ansible@PUBLIC_IP_OF_EC2_INSTANCE
```
- Update confluent_kafka_infra_setup/infra/terraform/terraform.auto.tfvars with required variables. keypair_public_key variable is already updated with ansible.pem.pub in previous step.

## How to Run 
```
cd confluent_kafka_infra_setup/scripts

# S3 Backend
sh provision.sh -h
sh provision.sh --instance lab01 --action apply

# Remote Backend (Terraform Cloud)
- Update confluent_kafka_infra_setup/infra/terraform/main.tf.remote with your Org details
- Uncomment instance variable value in confluent_kafka_infra_setup/infra/terraform/terraform.auto.tfvars
terraform login
sh remote_provision.sh plan|apply|destroy
```

## Post Set up
- /c/Windows/System32/drivers/etc/hosts and /etc/hosts (on All EC2s) are updated with IP details using null_resource in ec2.tf (refer confluent_kafka_infra_setup/etchostsBastion and confluent_kafka_infra_setup/scripts/etchostsWindows ). This will allow direct SSH to any EC2 from Local -> 
- Update Any Bastion Ec2 (if using) /etc/hosts with confluent_kafka_infra_setup/scripts/etchostsBastion file content
```
ssh -q -o "StrictHostKeyChecking=no" ansible@ansi-lab01-02.nrsh13-hadoop.com
```

## Contact
nrsh13@gmail.com
