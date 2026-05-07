provider "aws" {
  region = "us-east-1"
}
module "ec2_creation" {
  source = "/workspaces/Terraform/workspaces/modules/ec2"
  instance_type = lookup(var.instance_type, terraform.workspace, "t2.micro")
  ami_value = var.ami_value
}
variable "instance_type" {
  description = "Instance-type"
  type = map(string)
  default = {
    "dev" = "t2.micro"
    "stage" = "t2.medium"
  }
}
variable "ami_value" {
  description = "AMI_VALUE"
}
