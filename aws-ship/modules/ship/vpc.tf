
#data "aws_vpc" "default" {
#default = true
#}

#data "aws_subnet_ids" "all" {
#vpc_id = data.aws_vpc.default.id
#}

#locals {
#vpc_id            = data.aws_vpc.default.id
#availability_zone = "${var.aws_region}a"
#}

#data "aws_subnet" "selected" {
#vpc_id            = local.vpc_id
#availability_zone = local.availability_zone
#}

#locals {
#subnet_id = data.aws_subnet.selected.id
#}

#output "data_vpc" {
#value = data.aws_vpc.default
#}

# TODO: make a new vpc instead of naively using the default one

module "vpc" {
  source         = "terraform-aws-modules/vpc/aws"
  name           = "urbit-${var.ship}"
  cidr           = "10.0.0.0/16"
  public_subnets = ["10.0.101.0/24"]
  azs            = [local.availability_zone]
  tags           = var.common_tags
}

locals {
  availability_zone = "${var.aws_region}a"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = length(module.vpc.public_subnets) > 0 ? module.vpc.public_subnets[0] : ""
}

