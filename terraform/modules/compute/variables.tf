variable "name" {
  type = string
}

variable "app_subnet_id" {
  type = string
}

variable "bastion_subnet_id" {
  type = string
}

variable "app_security_group_id" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "bastion_instance_type" {
  type = string
}

variable "ami_id" {
  type    = string
  default = null
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "additional_ssh_public_keys" {
  type    = list(string)
  default = []
}

variable "ecr_repository_arn" {
  type = string
}

variable "database_secret_arn" {
  type = string
}
