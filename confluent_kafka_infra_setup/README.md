# AWS Kafka Infra Setup
## Description

This project builds N EC2 instances for Kafka Cluster

## Pre-requisites
- Update first 8 lines of confluent_kafka_infra_setup/scripts/provision.sh with your AWS Account Details.
- Run prereq-setup.sh to generate SSH Keys for EC2 Keypair -
```
$ sh prereq-setup-ssh-keypair.sh

info: Setting up ssh keys for Ec2 keypair for ssh to EC2s

info: SSH key pair already exists at /Users/naresh/.ssh. Skipping generation.

info: Update teraform.auto.tfvars with ansible user Public Key

info: Ansible user SSH Keys are stored in /Users/naresh/.ssh/id_rsa and /Users/naresh/.ssh/id_rsa.pub. Will be used for SSH like below

info: ssh ansible@PUBLIC_IP_OF_EC2_INSTANCE
```
- Update confluent_kafka_infra_setup/infra/terraform/terraform.auto.tfvars with required variables. keypair_public_key variable is already updated with id_rsa.pub in previous step.

## How to Run 
```
cd confluent_kafka_infra_setup/scripts

# S3 Backend
sh provision.sh -h
sh provision.sh --environment lab01 --action apply

# Remote Backend (Terraform Cloud)
- Update confluent_kafka_infra_setup/infra/terraform/main.tf.remote with your Org details
- Uncomment instance variable value in confluent_kafka_infra_setup/infra/terraform/terraform.auto.tfvars
terraform login
sh remote_provision.sh plan|apply|destroy
```

## Post Set up 
- Uses post-setup.sh script in null_resource in ec2.tf.
- /etc/hosts on the local machine as well as on All EC2s are updated with IP details using null_resource in ec2.tf
```
$ cd infra/terraform; 
$ sh ../../scripts/post-setup-etc-hosts.sh ansi lab01 1 .nrsh13-hadoop.com ansible

info: Prepare /etc/hosts for Corporate (Ec2s in Private Subnet) - Uses EC2s Private IP

Checking ansi-lab01-01.nrsh13-hadoop.com

info: Prepare /etc/hosts for non Corporate (Ec2s in Public Subnet) - Uses EC2s Public IP

Checking ansi-lab01-01.nrsh13-hadoop.com

info: Prepare /etc/hosts on macOS - assuming passwordless sudo for naresh

info: SCP the etchostsPublicIP to all EC2s

info: Checking ansi-lab01-01.nrsh13-hadoop.com

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

3.24.139.80	active-directory.nrsh13-hadoop.com	active-directory
3.26.196.62	ansi-lab01-01.nrsh13-hadoop.com		ansi-lab01-01

# Should be able to ssh using hostname now.

ssh -q -o "StrictHostKeyChecking=no" ansible@ansi-lab01-02.nrsh13-hadoop.com
```

## Contact
nrsh13@gmail.com
