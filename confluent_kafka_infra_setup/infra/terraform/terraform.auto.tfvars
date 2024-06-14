# AWS Account Details
aws_region = "ap-southeast-2"

# Envrionment Parameters
project = "nrsh13"
component = "ansi"
common_tags = {
  project = "nrsh13"
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
iam_role_permissions_boundary = "" #"arn:aws:iam::428706479336:policy/ANY-Account-Policy"

# EC2
ami = "ami-0808460885ff81045"
instance_type = "t3.large" #t3.2xlarge
instance_count = 3
passwordless_ssh_user = "ansible"
hostname_domain = ".nrsh13-hadoop.com" # generated hostname will be like - ansi-lab01-01.nrsh13-hadoop.com
keypair_public_key = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDczp7LC3n5rwjnrwx/YO/LETbigxt66eZOOliQRpcrIdXp4vzHJovYDvS0yTiKHTEZLg8xP1VOkNdpEi15SrUDQHg+Q7pjv1GIL0pZ6AOF7Naq2fSGy0TwN3HhqQ9jgqEH7MrsIihR3Ei7pFYV65+knisBv43llc0LClGJ1CD9Ce562XASXNSSW9ENdY8RMNqGeQTiWHrl+mAt/BvKiJnjPUVEMfu1jObTVLbW1lQfdsA5FbLxnYQD+Bz4W7X4tsNymJzac0VmcNjzo0SkaRrqsgJzQ8AmUrPE7d5Plc+VGgqssJN2ymL0vFXCOhRnde+jet//rGR26ung2jKE/scn9mbeYVZFIJgVoQf48p+QkY+gJGD9UzPJn8HXEdl6QT6FUOIOtb+FbDoOzpwlJa3hhXq7C64bq7B/n6xnUvbwYRCEc85l5YKWJX/kIxdUjKPg8vH2D3mZAfZz6Oxx7ilOHaz117TvqvWvtjURkRJMmEEpF5Bd1G0tQmCoQMEGrok= nrsh13
EOF
