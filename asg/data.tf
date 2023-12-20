data "aws_ami" "latest" {
  count       = var.lookup_ami ? 1 : 0
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Ec2ImageBuildFilter"
    values = [var.ami_identifier]
  }
}