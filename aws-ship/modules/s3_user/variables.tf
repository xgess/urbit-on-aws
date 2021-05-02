variable "identifier" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "iam_role_id" {
  # this iam_role will be empowered to do things to make this work
  type = string
}

variable "aws_region" { type = string }
variable "tmux_session_name" { type = string }
variable "rendered_scripts_path" { type = string }


