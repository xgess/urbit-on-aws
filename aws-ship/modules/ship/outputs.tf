output "ec2" {
  value = module.ec2
}

output "public_ip" {
  value = aws_eip.instance.public_ip
}


