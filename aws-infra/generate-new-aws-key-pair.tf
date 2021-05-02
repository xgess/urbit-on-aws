resource "tls_private_key" "new_ssh_key" {
  count     = var.generate_new_aws_key_pair ? 1 : 0
  algorithm = "RSA"
}

resource "local_file" "private_key_pem" {
  count = var.generate_new_aws_key_pair ? 1 : 0

  filename        = var.ssh_key_path
  content         = tls_private_key.new_ssh_key[0].private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "key_pair" {
  count = var.generate_new_aws_key_pair ? 1 : 0

  key_name   = var.ssh_key_name
  public_key = tls_private_key.new_ssh_key[0].public_key_openssh
  tags       = local.common_tags
}
