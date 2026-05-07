provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc_1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "as" {
  vpc_id = aws_vpc.vpc_1.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_route_table" "art" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
}

resource "aws_route_table_association" "arta" {
  subnet_id      = aws_subnet.as.id
  route_table_id = aws_route_table.art.id
}

resource "aws_internet_gateway" "ig" {
   vpc_id = aws_vpc.vpc_1.id
}


resource "aws_key_pair" "k1" {
  key_name = "New_key_terra"
  public_key = file("/workspaces/Terraform/provisions/.ssh/id_rsa.pub")
}

resource "aws_security_group" "sg1" {
  vpc_id = aws_vpc.vpc_1.id
   ingress{
    description = "Allow TCP"
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
   ingress{
    description = "Allow SSH"
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }
   egress{
    description = "Allow all"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
  
}
resource "aws_instance" "in1" {
  ami = "ami-091138d0f0d41ff90"
  instance_type = "t2.micro"
  key_name = aws_key_pair.k1.key_name
  vpc_security_group_ids = [aws_security_group.sg1.id]
  subnet_id = aws_subnet.as.id
connection {
  type = "ssh"
  user = "ubuntu"
  private_key = file("/workspaces/Terraform/provisions/.ssh/id_rsa")
  host = self.public_ip
}
provisioner "file" {
  source = "/workspaces/Terraform/provisions/app.py"
  destination = "/home/ubuntu/app.py"
}
provisioner "remote-exec" {
  inline = [ 
    "sudo apt update -y",
    "sudo apt-get install -y python3-pip python3-flask",
    "cd /home/ubuntu && sudo nohup python3 app.py > app.log 2>&1 &"
   ]
 }
 provisioner "local-exec" {
   command = "echo CHECK OUT UR APPLICATION IN ${self.public_ip} && terraform output -json > /workspaces/Terraform/provisions/terraform_outputs.json"
 }
}
output "ip_name" {
  value = aws_instance.in1.public_ip
}
