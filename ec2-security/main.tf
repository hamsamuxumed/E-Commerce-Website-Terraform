locals {
  account_id        = data.aws_caller_identity.current.account_id
  ec2-access-policy = templatefile("${path.module}/policies/iam-allow-ec2.json", local.ec2-access-vars)
  ec2-access-vars = {
    account_id = "${local.account_id}"
  }
}

resource "aws_security_group" "ec2_access" {
  name        = "${var.name}-ec2-access"
  description = "Attach this security group to resources that need access to the ec2 instances"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_iam_role" "ec2-iam-role" {
  name        = "ec2-iam-role"
  description = "The role for EC2 instances"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    aws_iam_policy.fsx_active_directory_access.arn,
    aws_iam_policy.ec2_resource_access.arn
  ]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : {
      "Effect" : "Allow",
      "Principal" : { "Service" : "ec2.amazonaws.com" },
      "Action" : "sts:AssumeRole"
    }
  })
  tags = var.tags
}

resource "aws_iam_policy" "ec2_resource_access" {
  name        = "ec2-access"
  path        = "/"
  description = "Policy to grant EC2 access"
  policy      = local.ec2-access-policy
}

resource "aws_iam_policy" "fsx_active_directory_access" {
  name        = "access-to-fsx-and-active-directory"
  path        = "/"
  description = "Policy to grant EC2 access to FSX, the Secret and Active Directory"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ],
        "Resource" : [
          "arn:aws:secretsmanager:${var.aws_region}:${local.account_id}:secret:fsx-managed-ad-details-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "secretsmanager:ListSecrets",
        "Resource" : "*"
        }, {
        "Effect" : "Allow",
        "Action" : [
          "fsx:DescribeFileSystems",
          "ds:DescribeDirectories"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Action" : [
          "s3:PutObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::${var.name}-database-backups/*",
        "Sid" : "BackupsIamAllowS3Write"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-iam-role.name
  tags = var.tags
}

resource "aws_security_group" "security_group_web" {
  for_each    = toset(var.ec2_web_roles)
  name        = "${var.name}-ec2-${each.key}-sg"
  description = "Inbound access to ${each.key} EC2 instances"
  tags = merge({
    "Name" = "${var.name}-ec2-${each.key}-sg"
  }, var.tags)

  vpc_id = var.vpc_id

  ingress = [
    {
      description      = "HTTP"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = []
      security_groups  = [aws_security_group.ec2_access.id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "HTTPS"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = []
      security_groups  = [aws_security_group.ec2_access.id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = ""
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]
}

resource "aws_security_group" "security_group_misc" {
  for_each    = toset(var.ec2_misc_roles)
  name        = "${var.name}-ec2-${each.key}-sg"
  description = "Inbound access to ${each.key} EC2 instances"
  tags = merge({
    "Name" = "${var.name}-ec2-${each.key}-sg"
  }, var.tags)

  vpc_id = var.vpc_id

  ingress = [
    {
      description      = "HTTP - From Web Instances"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = []
      security_groups  = [for web in aws_security_group.security_group_web : web.id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "HTTPS - From Web Instances"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = []
      security_groups  = [for web in aws_security_group.security_group_web : web.id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "SMTP - From Web Instances"
      protocol         = "tcp"
      from_port        = 25
      to_port          = 25
      cidr_blocks      = []
      security_groups  = [for web in aws_security_group.security_group_web : web.id]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "HTTP - Office"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = ["192.168.3.0/24", "192.168.7.0/24"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "HTTPS - Office"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = ["192.168.3.0/24", "192.168.7.0/24"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]

  egress = [
    {
      description      = ""
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
  ]

  depends_on = [
    aws_security_group.security_group_web
  ]
}
