resource "aws_autoscaling_group" "autoscaling_group" {
  name                = "asg-${var.ami_identifier}"
  vpc_zone_identifier = var.subnet_ids
  enabled_metrics = [
    "GroupAndWarmPoolDesiredCapacity",
    "GroupAndWarmPoolTotalCapacity",
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
    "WarmPoolDesiredCapacity",
    "WarmPoolMinSize",
    "WarmPoolPendingCapacity",
    "WarmPoolTerminatingCapacity",
    "WarmPoolTotalCapacity",
    "WarmPoolWarmedCapacity",
  ]
  desired_capacity = var.desired_capacity
  max_size         = var.max_size
  min_size         = var.min_size

  protect_from_scale_in = true

  target_group_arns = [
    var.target_group_arn
  ]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  force_delete              = false
  force_delete_warm_pool    = false
  wait_for_capacity_timeout = "10m"

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.ami_identifier}-ec2"
  }
}

resource "aws_launch_template" "launch_template" {
  name = "launch-template-${var.ami_identifier}"

  disable_api_termination = false

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  image_id = var.lookup_ami ? data.aws_ami.latest[0].id : var.image_id

  instance_type = var.instance_type

  key_name = var.key_name

  update_default_version = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size           = 50
      encrypted             = "true"
      volume_type           = "gp3"
      delete_on_termination = "true"
    }
  }

  # monitoring {
  #   enabled = true
  # }

  network_interfaces {
    security_groups             = var.security_group_ids
    associate_public_ip_address = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = var.tags
  }

  user_data = filebase64(var.user_data)
}
