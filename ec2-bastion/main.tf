data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Allow us to start SSM sessions
resource "aws_iam_role" "bastion_ssm_access" {
  name = "${var.name}-bastion-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = var.tags
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}

# Create instance profile to attach the above IAM role
resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "${var.name}-bastion-instance-profile"
  role = aws_iam_role.bastion_ssm_access.name

}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amzn-linux-2023-ami.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.bastion_instance_profile.name
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.security_group]

  tags = merge({
    "Name" = "${var.name}-bastion"
  }, var.tags)
}


