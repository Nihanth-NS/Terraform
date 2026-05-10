provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "public" {
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "public-1" {
  availability_zone = "us-east-1d"
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "private-1" {
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
}
resource "aws_subnet" "private-2" {
  availability_zone = "us-east-1d"
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = false
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}
resource "aws_route_table" "art" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}
resource "aws_route_table_association" "rta-1" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.art.id
}
resource "aws_route_table_association" "rta-2" {
  subnet_id = aws_subnet.public-1.id
  route_table_id = aws_route_table.art.id
}
resource "aws_eip" "EP" {

}
resource "aws_eip" "EP-1" {

}
resource "aws_nat_gateway" "ng" {
  subnet_id = aws_subnet.public.id
  allocation_id = aws_eip.EP.id
  depends_on = [ aws_internet_gateway.igw ]
}
resource "aws_nat_gateway" "ng-1" {
  subnet_id = aws_subnet.public-1.id
  allocation_id = aws_eip.EP-1.id
  depends_on = [ aws_internet_gateway.igw ]
}
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng.id
  }
}
resource "aws_route_table" "private-rt-1" {
  vpc_id = aws_vpc.vpc.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng-1.id
  }
}
resource "aws_route_table_association" "private-rta" {
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private-rt.id
}
resource "aws_route_table_association" "private-rta-1" {
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private-rt-1.id
}
resource "aws_security_group" "SG-public" {
  description = "Allow public"
  vpc_id = aws_vpc.vpc.id
  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "SG-private" {
  description = "Allow private"
  vpc_id = aws_vpc.vpc.id
  ingress{
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [aws_security_group.SG-public.id]
  }
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.SG-public.id]
  }
  ingress{
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_groups = [aws_security_group.SG-public.id]
  }
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "inst" {
  depends_on = [aws_nat_gateway.ng]
  ami           = "ami-091138d0f0d41ff90"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private-1.id
  vpc_security_group_ids = [ aws_security_group.SG-private.id ]
  associate_public_ip_address = false
  user_data = file("ab1.sh")
}
resource "aws_instance" "inst-2" {
  depends_on = [aws_nat_gateway.ng-1]
  ami           = "ami-091138d0f0d41ff90"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private-2.id
  vpc_security_group_ids = [ aws_security_group.SG-private.id ]
  associate_public_ip_address = false
  user_data = file("ab2.sh")
}
resource "aws_lb" "alb" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG-public.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public-1.id]
}
resource "aws_lb_target_group" "albtg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
    health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "lbtgat" {
  target_group_arn = aws_lb_target_group.albtg.arn
  target_id        = aws_instance.inst.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "lbtgat-1" {
  target_group_arn = aws_lb_target_group.albtg.arn
  target_id        = aws_instance.inst-2.id
  port             = 80
}
resource "aws_lb_listener" "alblis" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.albtg.arn
  }
}
# data "aws_alb" "albb" {
  
# }
output "ALB" {
  value = aws_lb.alb.dns_name
}

