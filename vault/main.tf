provider "aws" {
  region = "us-east-1"
}

provider "vault" {
  address = "http://15.135.141.207:8200"
  skip_child_token = true

  auth_login {
    path = "auth/approle/login"

    parameters = {
      role_id = "51783112-9f24-ec0c-1f3c-006f2f850fbb"
      secret_id = "e86aa165-234a-eaa1-02c4-5d5191fec544"
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
