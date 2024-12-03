#  創建負載均衡器（ALB）
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

#  負載均衡目標組
resource "aws_lb_target_group" "tg" {
  name     = "tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance" 
  vpc_id   = aws_vpc.vpc.id

  health_check {
    enabled  = true
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    matcher  = "200"
    interval = 10        # 健康檢查的間隔時間，默認為 30 秒
   
  }

  tags = {
    Name = "tg"
  }
}

#  創建負載均衡器監聽器
resource "aws_lb_listener" "listener1" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

}

# 將具體的目標（例如 EC2 實例、IP 地址等）附加到負載均衡器的目標組中
resource "aws_lb_target_group_attachment" "attachment_1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attachment_2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web2.id
  port             = 80
}