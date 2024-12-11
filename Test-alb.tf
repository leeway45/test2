# 創建 ALB
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "tg" {
  name       = "tg"
  port       = 80
  protocol   = "HTTP"
  target_type = "instance"
  vpc_id     = aws_vpc.vpc.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200"
  }

  tags = {
    Name = "tg"
  }
}

# ALB Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
    tags = {
    Name = "listener"
  }
}



resource "aws_launch_template" "web_t" {
  name          = "web-t"
  image_id      = "ami-0232d56f0b25fa9b1"
  instance_type = "t2.micro"
  key_name      = "li2-key"
  network_interfaces {
    security_groups             = [aws_security_group.sg1.id]
    associate_public_ip_address = false
  }

  # iam_instance_profile {
  #   name = data.aws_iam_instance_profile.existing_instance_profile.name
  # }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ec2-auto"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 2
  launch_template {
    id      = aws_launch_template.web_t.id
    version = "$Latest"
  }
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  health_check_type    = "ELB"
  health_check_grace_period = 30

  # 使用多個 tag 塊，而不是 tags
  tag {
    key                 = "Name"
    value               = "ec2-web"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "prod"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.tg.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale_out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale_in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "alb_request_count_high" {
  alarm_name          = "alb_request_count_high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "2"  
  alarm_description   = "Alarm when ALB request count exceeds 2"

  dimensions = {
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_request_count_low" {
  alarm_name          = "alb_request_count_low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "2"  
  alarm_description   = "Alarm when ALB request count falls below 2"

  dimensions = {
    TargetGroup  = aws_lb_target_group.tg.arn_suffix
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  alarm_actions = [aws_autoscaling_policy.scale_in_policy.arn]
}

resource "aws_autoscaling_lifecycle_hook" "autoscaling_lifecycle_hook" {
  name                   = "autoscaling_lifecycle_hook"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_LAUNCHING"
  default_result         = "CONTINUE"
  heartbeat_timeout      = 120
}
