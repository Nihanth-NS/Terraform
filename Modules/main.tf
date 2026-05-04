provider "aws"{
    region = "us-east-1"
}
module "ec2_create"{
    source = "/workspaces/Terraform/modules/ec2"
    region_aws = "us-east-1" (Name of variables.tf in module)
    ami_value = ""
}
