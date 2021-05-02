variable "aws_region" {
  type = string
}

variable "identifier" {
  type = string
}

variable "ship" {
  description = "Name of the ship: e.g. sampel-palnet"
  type        = string
}

variable "domain" {
  description = "Domain name where you want your ship to run: e.g. example.com"
  type        = string
}

variable "allow_ssh_cidrs" {
  description = "Lock this down to your home network"
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "instance_username" {
  default = "ubuntu"
}

variable "key_name" {
  description = "Name of the already existing ssh key to assign to the instance"
  type        = string
}

variable "udp_port" {
  default = 49152
}

variable "rendered_scripts_path" {
  type = string
}

variable "tmux_session_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
