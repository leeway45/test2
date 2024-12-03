# 創建子網
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.10.0/24"
  
  tags = {
    Name = "subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "192.168.11.0/24"
  
  tags = {
    Name = "subnet2"
  }
}
