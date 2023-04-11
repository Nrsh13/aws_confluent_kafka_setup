# AWS Kafka Infra Setup
## Description

This project builds N EC2 instances for Kafka Cluster

## Pre-requisites
- Update aws_kafka_infra_setup/scripts/set_env.sh with your AWS Account Details.
- Generate SSH Keys for EC2 Keypair -
```
cd aws_kafka_infra_setup/scripts
ssh-keygen -b 2048 -t rsa -f ansible.pem -q -C ansible -N ""
nrsh13@dell-laptop MINGW64 ~/Desktop/aws_kafka_infra_setup/scripts
$ ll
total 13K
-rwxr-xr-x 1 nrsh13 197121  926 Apr  9 12:15 setup_env.sh
-rw-r--r-- 1 nrsh13 197121  561 Apr 11 04:52 ansible.pem.pub
-rw-r--r-- 1 nrsh13 197121 2.6K Apr 11 04:52 ansible.pem
-rw-r--r-- 1 nrsh13 197121 3.8K Apr 11 05:33 provision.sh
```
- Update aws_kafka_infra_setup/infra/terraform/terraform.auto.tfvars with required variables (including generated ansible.pub in previous step). This also has instance_count to decide how many Ec2 you want to deploy.

## How to Run 
```
cd aws_kafka_infra_setup/scripts

# S3 Backend
sh provision.sh -h
sh provision.sh --instance lab01 --action apply

# Remove Backend (Terraform Cloud)
- Update aws_kafka_infra_setup/infra/terraform/main.tf.remote with your Org details
- Uncomment instance variable value in aws_kafka_infra_setup/infra/terraform/terraform.auto.tfvars
terraform login
sh remote_provision.sh plan|apply|destroy
```

## Post Set up - On All EC2s
- Use EC2 Private IP to update /etc/hosts and set hostname on the EC2 instnaces.
```
ssh -i "ansible.pem" ec2-user@ec2-54-206-93-240.ap-southeast-2.compute.amazonaws.com
sudo su -
vi /etc/hosts and add similar to below.
172.31.15.39	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01
172.31.15.40	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01

hostnamectl set-hostname ansi-lab01-01.nrsh13-hadoop.com
```

## Contact
nrsh13@gmail.com
