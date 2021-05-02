locals {
  bucketname = "${var.identifier}-uploads-${var.aws_region}"
  username   = "${var.identifier}-s3-uploader"
}

resource "aws_s3_bucket" "uploads" {
  bucket = local.bucketname
  acl    = "public-read"

  cors_rule {
    allowed_headers = ["*"]
    allowed_origins = ["*"]
    allowed_methods = ["PUT", "GET"]
  }

  tags = var.common_tags
}

resource "aws_iam_user" "s3_uploader" {
  name = local.username
  tags = var.common_tags
}

data "aws_iam_policy_document" "s3_uploads" {
  statement {
    actions   = ["secretsmanager:*"]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.identifier}*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.bucketname}/*"]
    effect    = "Allow"
  }
}

locals {
  secrets_manager_entry = "${local.username}-access-keys"
}

resource "aws_iam_user_policy" "uploads" {
  name   = "${local.bucketname}-upload-policy"
  user   = aws_iam_user.s3_uploader.name
  policy = data.aws_iam_policy_document.s3_uploads.json
}

resource "aws_iam_role_policy" "create_uploader_access" {
  name   = "${local.bucketname}-upload-access"
  role   = var.iam_role_id
  policy = data.aws_iam_policy_document.s3_uploads.json
}


resource "aws_iam_access_key" "user" {
  user = aws_iam_user.s3_uploader.name
}

resource "aws_secretsmanager_secret" "s3_uploader" {
  name                    = local.secrets_manager_entry
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "s3_uploader" {
  secret_id = aws_secretsmanager_secret.s3_uploader.id
  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.user.id
    secret_access_key = aws_iam_access_key.user.secret
    bucket            = local.bucketname
  })
}

resource "local_file" "s3_uploads" {
  filename = "${var.rendered_scripts_path}/add_s3_uploads.sh"
  content = templatefile("${path.module}/scripts/add_s3_uploads.sh.tpl", {
    tmux_session_name = var.tmux_session_name
    secret_entry_name = local.secrets_manager_entry
    aws_region        = var.aws_region
  })
  file_permission = "0755"
}

############################

output "bucket" {
  value = aws_s3_bucket.uploads.id
}

output "username" {
  value = aws_iam_user.s3_uploader.name
}

output "user_aws_creds" {
  value = {
    access_key_id = aws_iam_access_key.user.id
  }
}

output "scripts" {
  value = [local_file.s3_uploads.filename]
}

output "secrets_manager_entry_name" {
  value = local.secrets_manager_entry
}
