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
instance_type = "t3.2xlarge"
instance_count=1
passwordless_ssh_user="ansible"
keypair_public_key = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyaWxlhIbhvZgUJD7qI70a4dWe6AbgZRHgC+TesPHi56IYnNgCDZ4J8VFff3SCe9ho91TjnLXOeZPWM056mQr09bDMtgMpbv8DG+kaAdgVq0D/y4Ae3QLnBNt1fqvrrjod63HMolFDoCDzBDdrFU91u7HSkpcNFWFprcameqwXY8FHSkfwRrIk2UPuPI4nDX5QZ1tsYzmn8PFkyMQi4n4uq3K9P67pWZRulSMqukfuHV8XmFyACL7hbt6knCAyRMb9q9fjWdcEbqRgMNGqbTIcztXYZEsaIqay0PrITXPmzyEYC32mXPCzBX81852gGc47/2pYk+6lsfyoDspI2Dyj ansible
EOF
