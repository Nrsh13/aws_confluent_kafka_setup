######################### Common Variables #########################

variable "project" {
description = "Project name say nrsh13"
type = string
}

variable "aws_region" {
  description = "(Required) AWS Region"
  type = string
}

variable "environment" {
  description = "(Required) Environment name. E.g. rstnonprod"
  type = string
}

variable "component" {
  description = "(Required) Component Name. E.g. land, disp, bdm, emr etc"
  type = string
}

variable "common_tags" {
  description = "Tags common to the component"
  type = map
}

variable "specific_tags" {
  description = "Tags specific to an instance of the component"
  type = map
}


######################### Component Variables #########################

variable "ami" {
  description = "The AMI ID"
  type = string
}

variable "instance_type" {
  description = "The Instance Type"
  type = string
}

variable "instance_count" {
  description = "How many instances you need"
  type = string
  default = "1"
}

variable "hostname_domain" {
  description = "Hostname Domain. for eq. testhost.<HOSTDOMAIN.COM> ansi-lab01-01.nrsh13-hadoop.com"
  default = ".nrsh13-hadoop.com"
}

# IAM Role
variable "create" {
  default = "true"
  description = "Create an IAM role"
}

variable "create_instance_profile" {
  default = "true"
  description = "Create an IAM Instance Profile"
}

variable "mandatory_policies" {
   description = "List of extra iam policies to be attached to the role"
   type = list
   default = []
}

variable "extra_policy_count" {
   description = "The Number of extra policies to be attached to the role"
   type = string
}

variable "extra_policy_arns" {
   description = "Extra Policy Arns"
   type = list
   default = []
}

variable "iam_role_permissions_boundary" {
  type              = string
  description       = "The permissions boundary to be used in the raw-batch-locker IAM role"
  default           = ""
}

# SSH 
variable "ssh_private_key_file_location" {
  type  = string
  description = "File will be used by local-exec in ec2.tf"
  default = "~/.ssh/id_rsa"
}

variable "keypair_public_key" {
  description = "Keypair public key. Generate using ssh-keygen -C userName"
}

variable "passwordless_ssh_user" {
  description = "User for Password less SSH for Ansible."
  type = string
}

# ALB
# https_enabled_ui needs Certificate in AWS ACM. Get acm_cert_domain_name (under AWS -> ACM -> List Certificates -> Domain Name of your cert. acm_cert_domain_name is generally same as Common Name of the cert.
# Below 3 are important variables when using in corporate or personal environment
variable "https_enabled_ui" { 
  type = bool 
  default = true
} # true or false
variable "load_balancer_is_internal" {
  default = "false"
} # Important for UI Access else LB throws - This site can’t be reached
variable "route53_hosted_zone_private" {
  default = "false"
}
variable "acm_cert_domain_name" {}
variable "route53_hosted_zone" {}
variable "route53_hosted_zone_dns" {}
