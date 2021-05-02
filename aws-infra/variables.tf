variable "aws_profile" { type = string }
variable "aws_region" { type = string }
variable "output_config_path" { type = string }

# for creating the ssh key and aws key pair
variable "generate_new_aws_key_pair" {
  description = "If you want to create a new SSH keypair locally and push the public key to AWS for using here."
  type        = bool
}

variable "ssh_key_name" {
  description = "Name of the key pair to create in AWS - only if generate_new_aws_key_pair is true"
  type        = string
  default     = null
}

variable "ssh_key_path" {
  description = "Path to write a new ssh key -- only if generate_new_aws_key_pair is true"
  type        = string
  default     = null
}
