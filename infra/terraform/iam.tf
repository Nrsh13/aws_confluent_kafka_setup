locals {
  mandatory_policy_arns     = formatlist("arn:aws:iam::%s:policy/%s", var.aws_account_id, var.mandatory_policies)
  attach_policy_arns        = concat(local.mandatory_policy_arns, var.extra_policy_arns)
  create_permissions_policy = var.create != "" ? 1 : 0
}

data "aws_iam_policy_document" "iam_base_policy" {
  policy_id = "S3-Access-Policy"
  version   = "2012-10-17"
  statement {
    sid    = "S3AndSSMAccess"
    effect = "Allow"
    actions = [
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetObject*",
        "s3:PutObject*",
        "s3:DeleteObject*",
        "s3:GetLifecycleConfiguration",
        "s3:PutLifecycleConfiguration",
        "ssm:PutParameter",
        "ssm:GetParameterHistory",
        "ssm:GetParametersByPath",
        "ssm:GetParameters",
        "ssm:GetParameter"
    ]
    resources = [
        "*"
    ]
   }

  statement {
    sid    = "LoggingAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:Describe*",
      "ec2:DescribeInstances",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]

    resources = [
	"*"
    ]
  }

}

## IAM Role
resource "aws_iam_role" "this" {
  name                 = "${var.environment}-${var.instance}-${var.component}EC2Role"
  description          = "${var.environment}-${var.instance}-${var.component}EC2Role"
  permissions_boundary = "${var.iam_role_permissions_boundary}"
  assume_role_policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": [
             "ec2.amazonaws.com",
             "ssm.amazonaws.com"
          ]
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
  EOF
}

# Creates a policy to attach to the role
resource "aws_iam_policy" "this" {
  count  = local.create_permissions_policy
  name   = "${var.environment}-${var.instance}-${var.component}EC2RolePolicy"
  policy = data.aws_iam_policy_document.iam_base_policy.json
}

######
# IAM Role, Policy, and Policy Attachment

# Attach the policy just createdpolicy_name to the role.
resource "aws_iam_role_policy_attachment" "this" {
  count      = local.create_permissions_policy
  role       = aws_iam_role.this.id
  policy_arn = aws_iam_policy.this.*.arn[count.index]
}


# Attach the extra policies if supplied.
resource "aws_iam_role_policy_attachment" "extra" {
  count      = var.create ? length(local.attach_policy_arns) : 0
  role       = aws_iam_role.this.id
  policy_arn = local.attach_policy_arns[count.index]
}

resource "aws_iam_instance_profile" "this" {
  count = var.create && var.create_instance_profile ? 1 : 0
  name  = "${var.environment}-${var.instance}-${var.component}EC2RoleInstanceProfile"
  role  = aws_iam_role.this.name
}