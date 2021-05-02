
locals {
  primary_region = var.aws_region
  replica_region = var.aws_region == "us-west-2" ? "us-east-2" : "us-west-2"
  name_prefix    = "urbit-tf-state"
}

provider "aws" {
  profile = var.aws_profile
  region  = local.primary_region
}

provider "aws" {
  alias  = "replica"
  region = local.replica_region
}

locals {
  common_tags = {
    "Purpose"   = "urbit"
    "Terraform" = "true"
    "Project"   = "aws-infra"
  }
}

module "remote_state" {
  source = "nozaq/remote-state-s3-backend/aws"

  providers = {
    aws         = aws
    aws.replica = aws.replica
  }
  state_bucket_prefix              = "${local.name_prefix}-"
  replica_bucket_prefix            = "${local.name_prefix}-replica-"
  terraform_iam_policy_name_prefix = "${local.name_prefix}-deployer-"
  dynamodb_table_name              = "${local.name_prefix}-lock"
  iam_role_name_prefix             = "${local.name_prefix}-replication-"
  iam_policy_name_prefix           = "${local.name_prefix}-replication-"
  kms_key_description              = "Encrypt urbit-terraform-state bucket"
  terraform_iam_policy_create      = true

  tags = local.common_tags
}

resource "local_file" "config_to_use_remote_state" {
  filename = var.output_config_path
  content  = <<EOF
bucket = "${module.remote_state.state_bucket.bucket}"
key = "terraform.tfstate"
region = "${local.primary_region}"
encrypt = true
kms_key_id = "${module.remote_state.kms_key.id}"
dynamodb_table = "${module.remote_state.dynamodb_table.name}"
EOF
}
