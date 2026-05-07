provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "ec21" {
  instance_type = var.instance_type
  ami = var.ami_value
}
variable "instance_type" {
  description = "Instance type"
}
variable "ami_value" {
  description = "ami_key"
}
