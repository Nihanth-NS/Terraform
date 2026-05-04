output "pub_ip"{
    description = "Pubic ip"
    value = aws_instance.wb1.public_ip
}
