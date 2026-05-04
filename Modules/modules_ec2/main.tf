resource "aws_instance" "wb1"{
    region=var.region_aws
    ami=var.ami_value
}
