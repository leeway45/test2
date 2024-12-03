# 創建 VPC
resource "aws_vpc" "vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc"
  }

}

# 創建 Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}


#  創建 EC2 實例
resource "aws_instance" "web1" {
  ami                         = "ami-03f584e50b2d32776"
  instance_type               = "t2.micro"
  key_name                    = "li2-key"
  subnet_id                   = aws_subnet.subnet1.id
  vpc_security_group_ids       = [aws_security_group.sg1.id]
  


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
    Name = "web1"
  }
}

resource "aws_instance" "web2" {
  ami                         = "ami-03f584e50b2d32776"
  instance_type               = "t2.micro"
  key_name                    = "li2-key"
  subnet_id                   = aws_subnet.subnet2.id
  vpc_security_group_ids       = [aws_security_group.sg1.id]
  

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
    Name = "web2"
  }
}
