provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {}
}

locals {
  common_tags = {
    "Purpose"   = "urbit"
    "Ship"      = var.ship
    "Terraform" = "true"
  }
  rendered_scripts_path = "${path.module}/rendered-scripts/${var.ship}"
  tmux_session_name     = "urbit"
  identifier            = "urbit-${var.ship}"
}

module "ship" {
  source      = "./modules/ship"
  common_tags = local.common_tags

  identifier            = local.identifier
  ship                  = var.ship
  domain                = var.domain
  key_name              = var.key_name
  aws_region            = var.aws_region
  tmux_session_name     = local.tmux_session_name
  rendered_scripts_path = local.rendered_scripts_path
}

module "s3_uploader" {
  # make an s3 bucket for uploads and a user that has access ONLY to that bucket
  # spits out a script that needs to be run on the instance
  source = "./modules/s3_user"

  identifier  = "urbit-${var.ship}"
  iam_role_id = module.ship.instance_iam_role_id
  aws_region  = var.aws_region

  tmux_session_name     = local.tmux_session_name
  rendered_scripts_path = local.rendered_scripts_path
  common_tags           = local.common_tags
}

output "ship" {
  value = module.ship
}

output "s3_uploader" {
  value = module.s3_uploader
}
#
