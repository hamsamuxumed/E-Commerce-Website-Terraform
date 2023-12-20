## Data Sources - Retrieve resources from outside this module
data "aws_availability_zones" "available" {}

## Locals - reusable variables for repeated use within this module
#locals {
#  user_data = templatefile("${path.module}/user_data/webstartup.ps1", {})
#}

resource "aws_security_group" "security_group" {
  name        = lookup(var.override_names, "ec2_security_group", "${var.name}-ec2-${var.serveruse}-sg")
  description = lookup(var.override_names, "ec2_security_group_description", "Inbound access to ${var.serveruse} EC2 instances")
  tags = merge({
    "Name" = "${var.name}-ec2-${var.serveruse}-sg"
  }, var.tags)

  vpc_id = var.vpc_id

  ingress = [
    {
      description      = "HTTP"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = []
      security_groups  = [var.access_security_group]
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
      security_groups  = [var.access_security_group]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    },
    {
      description      = "RDP"
      protocol         = "tcp"
      from_port        = 3389
      to_port          = 3389
      cidr_blocks      = ["0.0.0.0/0"]
      security_groups  = [var.access_security_group]
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

resource "aws_iam_role" "ec2-iam-role" {
  name               = "ec2-iam-role"
  description        = "The role for EC2 insatnces"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": {
"Effect": "Allow",
"Principal": {"Service": "ec2.amazonaws.com"},
"Action": "sts:AssumeRole"
}
}
EOF
  tags               = var.tags
}

resource "aws_iam_instance_profile" "ec2-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-iam-role.name
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-s3-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_instance" "ec2" {
  for_each      = toset(var.subnets)
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = each.value

  vpc_security_group_ids = [aws_security_group.security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2-iam-profile.name

  user_data = var.user_data

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    delete_on_termination = true
    tags = merge({
      "Name" = "${var.name}-ec2-${var.serveruse}"
    }, var.tags)
  }
# add variables to encryted, device name, volume type and size 
  ebs_block_device {
    delete_on_termination = true
    encrypted = true
    device_name = "/dev/sdh"
    volume_type = "gp3"
    volume_size = 40
    tags = merge({
      "Name" = "${var.name}-ec2-${var.serveruse}"
    }, var.tags)
  }

  tags = merge({
    "Name" = "${var.name}-ec2-${var.serveruse}"
  }, var.tags, var.schedule)
}
