module "ship_sg" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "urbit-${var.ship}-sg"
  vpc_id = local.vpc_id
  ingress_with_cidr_blocks = [
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = join(",", var.allow_ssh_cidrs)
    },
    {
      description = "urbit UDP traffic"
      from_port   = var.udp_port
      to_port     = var.udp_port
      protocol    = "udp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-8080-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  egress_rules = ["all-all"]
}


resource "aws_iam_role" "instance_role" {
  name = "urbit-${var.ship}-instance-role"
  tags = var.common_tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "instance_iam_role_id" {
  value = aws_iam_role.instance_role.id
}

resource "aws_iam_instance_profile" "instance" {
  name = "urbit-${var.ship}-instance-profile"
  role = aws_iam_role.instance_role.name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    # TODO: if you're looking at this, replace this line with this one to 
    # get an updated AMI. Will get a new instance.
    # values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210430"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

locals {
  instance_username = "ubuntu"
  user_data = templatefile("${path.module}/scripts/on_launch.sh.tpl", {
    USERNAME = local.instance_username
  })
}

module "ec2" {
  source         = "terraform-aws-modules/ec2-instance/aws"
  version        = "~> 2.0"
  instance_count = 1
  name           = "${var.ship}-instance"

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [module.ship_sg.security_group_id]
  subnet_id                   = local.subnet_id
  monitoring                  = false
  associate_public_ip_address = true
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  user_data = local.user_data
  tags      = var.common_tags
}

resource "aws_volume_attachment" "pier_data" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.pier_data.id
  instance_id = module.ec2.id[0]
}

resource "aws_ebs_volume" "pier_data" {
  # TODO: encrypt this
  availability_zone = local.availability_zone
  size              = 100
}

resource "aws_eip" "instance" {
  vpc      = true
  instance = module.ec2.id[0]
}

locals {
  eip = aws_eip.instance.public_ip
}


