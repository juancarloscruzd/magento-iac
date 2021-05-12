resource "tls_private_key" "private" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" { 
  filename = "${path.module}/magento_master_private_key.pem"
  content = tls_private_key.private.private_key_pem
}


resource "aws_key_pair" "generated_key" {
  key_name   = "magento_master_key_name"
  public_key = tls_private_key.private.public_key_openssh
}