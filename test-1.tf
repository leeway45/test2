# 1. Terraform 配置塊
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.78.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

# 2. 創建 VPC
resource "aws_vpc" "li-vpc" {
  cidr_block       = "172.16.0.0/16"
  
  tags = {
    Name = "li-vpc"
  }
}

# 3. 創建 Internet Gateway
resource "aws_internet_gateway" "li-igw" {
  vpc_id = aws_vpc.li-vpc.id

  tags = {
    Name = "li-igw"
  }
}

# 4. 創建子網
resource "aws_subnet" "li-web-1a" {
  vpc_id                  = aws_vpc.li-vpc.id
  cidr_block              = "172.16.10.0/24"
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "li-web-1a"
  }
}

resource "aws_subnet" "li-web-1c" {
  vpc_id                  = aws_vpc.li-vpc.id
  cidr_block              = "172.16.11.0/24"
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "li-web-1c"
  }
}

resource "aws_subnet" "li-db-1a" {
  vpc_id                  = aws_vpc.li-vpc.id
  cidr_block              = "172.16.20.0/24"
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "li-db-1a"
  }
}

# 5. 創建路由表
resource "aws_route_table" "li-rtb" {
  vpc_id = aws_vpc.li-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.li-igw.id
  }

  tags = {
    Name = "li-rtb"
  }
}

# 路由表與子網關聯
resource "aws_route_table_association" "li-association-web-1a" {
  subnet_id      = aws_subnet.li-web-1a.id
  route_table_id = aws_route_table.li-rtb.id
}

resource "aws_route_table_association" "li-association-web-1c" {
  subnet_id      = aws_subnet.li-web-1c.id
  route_table_id = aws_route_table.li-rtb.id
}


# 6. 創建安全組
resource "aws_security_group" "li-web-sg" {
  vpc_id = aws_vpc.li-vpc.id
  name   = "li-web-sg"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.li-alb-sg.id]  # 允許來自 ALB 的 HTTP 流量
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 允許SSH流量進入
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 允許所有流出流量
  }

  tags = {
    Name = "li-web-sg"
  }
}

resource "aws_security_group" "li-alb-sg" {
  vpc_id = aws_vpc.li-vpc.id
  name   = "li-alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 允許任何來源的 HTTP 流量進入
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 允許SSH流量進入
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 允許所有流出流量
  }

  tags = {
    Name = "li-alb-sg"
  }
}

resource "aws_security_group" "li-db-sg" {
  vpc_id = aws_vpc.li-vpc.id
  name   = "li-db-sg"

  ingress {
    from_port       = 3306  # 数据库端口，按实际使用的数据库修改
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.li-web-sg.id]  # 僅允許從li-web1和li-web2訪問
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "li-db-sg"
  }
}

# 7. 創建 EC2 實例
resource "aws_instance" "li-web1" {
  ami                         = "ami-03f584e50b2d32776"
  instance_type               = "t2.micro"
  key_name                    = "li2-key"
  subnet_id                   = aws_subnet.li-web-1a.id
  vpc_security_group_ids       = [aws_security_group.li-web-sg.id]
  associate_public_ip_address  = false


  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker pull jojobeast814/li-web
    sudo docker run -d -p 80:80 jojobeast814/li-web
    EOF


  tags = {
    Name = "li-web1"
  }
}

resource "aws_instance" "li-web2" {
  ami                         = "ami-03f584e50b2d32776"
  instance_type               = "t2.micro"
  key_name                    = "li2-key"
  subnet_id                   = aws_subnet.li-web-1c.id
  vpc_security_group_ids       = [aws_security_group.li-web-sg.id]
  associate_public_ip_address  = false

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker pull jojobeast814/team-tw
    sudo docker run -d -p 80:80 jojobeast814/team-tw
    EOF


  tags = {
    Name = "li-web2"
  }
}

resource "aws_instance" "li-db1" {
  ami                         = "ami-03f584e50b2d32776"
  instance_type               = "t2.micro"
  key_name                    = "li2-key"
  subnet_id                   = aws_subnet.li-db-1a.id
  vpc_security_group_ids       = [aws_security_group.li-db-sg.id]
  associate_public_ip_address  = false  # 私有子網中無公共IP

  tags = {
    Name = "li-db1"
  }
}

# 8. 創建負載均衡器（ALB）
resource "aws_lb" "li-web-alb" {
  name               = "li-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.li-alb-sg.id]
  subnets            = [aws_subnet.li-web-1a.id, aws_subnet.li-web-1c.id]

  tags = {
    Name = "li-web-alb"
  }
}

# 9. 負載均衡目標組
resource "aws_lb_target_group" "li-tg" {
  name     = "li-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance" 
  vpc_id   = aws_vpc.li-vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    matcher  = "200"
    interval            = 15        # 健康檢查的間隔時間，默認為 30 秒
    timeout             = 8         # 超時時間，等待目標回應的最大秒數，默認為 5 秒
    healthy_threshold   = 5         # 需要通過健康檢查的次數才能標記為健康，默認為 3
    unhealthy_threshold = 5         # 連續失敗次數才能標記為不健康，默認為 2
  }

  tags = {
    Name = "li-tg"
  }
}

# 10. 創建負載均衡器監聽器
resource "aws_lb_listener" "li-alb-listener" {
  load_balancer_arn = aws_lb.li-web-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.li-tg.arn
  }


}
resource "aws_lb_target_group_attachment" "li_attachment_1" {
  target_group_arn = aws_lb_target_group.li-tg.arn
  target_id        = aws_instance.li-web1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "li_attachment_2" {
  target_group_arn = aws_lb_target_group.li-tg.arn
  target_id        = aws_instance.li-web2.id
  port             = 80
}


