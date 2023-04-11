# AWS Account Details
aws_account_id = "428706479336"
aws_region = "ap-southeast-2"
vpc_id = "vpc-8f84d6e8"
vpc_cidr = ["172.31.0.0/16"]

# Envrionment Parameters
environment = "nrsh13"
instance = "lab01"
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
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2r4v5DQrV1e7hzFpC5OA2wXBJ6tbP8ZXU/6TjcXAzMvYhqQJXs+gibq6ga9zS4e+BipOqOn/5S/gOShCviwPqGMg7uHBvRTefJ10/go0/ekAmae7wAkjxHcDtoiYT7PbA436ktczvYAGL/RuK0D6ZkR2JlkH/2ZG4hThL/qCc+yqJd3umAdGXebcObtvU9pcRJu2l37k6blc+8KSNwvuWwrRFiO+899hn5+70NrLbW7ICB12ryZJwSprsmYyYlfOtiDVBCuWLHuUTxkffOfascmMGXZBQwCGE7WxkD8kwTGT2SuSiH8UjGEOT3HpFA+CD6eBZiMdzXqvIqnxp3tHirfsKrQbtOI5ov5D0XHAMh9sfCXx29oIQbtcLVQ2CN4GI4Gcb3MoYRFsXzCf0OgEkVYXH9FcSjCAiBHEk/HZY6iuh+xYr/dbr12lH7QXMznNjOR4obUWGtm9lzwLn8dNE5djoAG8v4yWfx5KaH9rMwbnOBmv4bh8Wxuwp6oDM0IU= ansible
EOF

