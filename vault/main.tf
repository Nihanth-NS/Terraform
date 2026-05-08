provider "aws" {
  region = "us-east-1"
}

provider "vault" {
  address = "http://ip_address:8200"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id = ""
      secret_id = ""
    }
  }
}
data "vault_kv_secret_v2" "vksv" {
  mount = "kv"
  name  = "test1"
}
output "check" {
  value = keys(data.vault_kv_secret_v2.vksv.data)
  sensitive = true
}
resource "aws_instance" "abc" {
  ami = "ami-0261755bbcb8c4a84"
  instance_type = "t2.micro"
  tags = {
    name = "Nihanth"
    secret = data.vault_kv_secret_v2.vksv.data["Nihanth"]
  }
}
