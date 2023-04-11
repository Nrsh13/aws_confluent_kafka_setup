# AWS Account Details
aws_account_id = "428706479336"
aws_region = "ap-southeast-2"
vpc_id = "vpc-8f84d6e8"
vpc_cidr = ["172.31.0.0/16"]

# Envrionment Parameters
environment = "nrsh13"
#instance = "lab01" # Setting in provision.sh. Uncomment for remote_provision.sh
component = "ansi"
common_tags = {
  Environment = "nrsh13"
}
specific_tags = {
  domain_join = "false"
}

# IAM
mandatory_policies = [
]
extra_policy_count = 2
extra_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AdministratorAccess"
]

# EC2
ami = "ami-0808460885ff81045"
instance_type = "t3.large" #t3.2xlarge
instance_count = 3
passwordless_ssh_user = "ansible"
hostname_domain = ".nrsh13-hadoop.com" # generated hostname will be like - ansi-lab01-01.nrsh13-hadoop.com
keypair_public_key = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdauexfShE2i8NpID934ORmfjcoGXhorOpgiPX6Mh1BXlBXM11iq5utvRzv3MBSNqrQxYQC7A0TL/qfwnZCqUfuU1rB8ce5o7NUCsyMvNe6MOla5AmcbKyMWrH8rxQJ5GF1EqlonQZ0PABxGM040X/QWl2RBAKUR/vBD643xjAcutpRSxF0vVKkZeBL2ZbXobGRSh0KWrc/OdRnFlKBWuCA6ZJv+VvI590xaFWTtKZEREDUBLDPHjBgL53ysCd/Am4aHstDpl80A6YbTM330YoQpLtTPaUs0jH17V4HmrPQvOYgnSxwJyKovwlXxfWFrVy1mpOeui3Earv83o1ooBB ansible
EOF
