variable "aws_region" {
  description = "AWS region in which to create the VPC and host."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Deployment name used to label resources."
  type        = string
  nullable    = false
  default     = "development"
}

variable "app_name" {
  description = "Application name used to label resources."
  type        = string
  nullable    = false
  default     = "somaquiz"
}

variable "vpc_cidr" {
  description = "Private IPv4 CIDR for the VPC. The first /24 becomes the public subnet."
  type        = string
  nullable    = false
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && try(contains(range(16, 25), tonumber(split("/", var.vpc_cidr)[1])), false)
    error_message = "Use an IPv4 VPC CIDR with a prefix between /16 and /24."
  }
}

variable "ssh_cidr" {
  description = "Public IPv4 address of the operator or Ansible controller, as a /32."
  type        = string
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "Use one IPv4 address in /32 notation for SSH."
  }
}

variable "additional_ssh_cidrs" {
  description = "Public IPv4 /32s for other authorized SSH operators."
  type        = set(string)
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for cidr in var.additional_ssh_cidrs : try(can(cidrnetmask(cidr)) && endswith(cidr, "/32"), false)])
    error_message = "Use one IPv4 address in /32 notation per additional operator."
  }
}

variable "app_cidrs" {
  description = "IPv4 CIDRs allowed to reach the application directly. Empty means SSH tunnel only."
  type        = set(string)
  nullable    = false
  default     = []

  validation {
    condition     = alltrue([for cidr in var.app_cidrs : can(cidrnetmask(cidr)) && try(tonumber(split("/", cidr)[1]) > 0, false)])
    error_message = "Use specific IPv4 CIDRs for app access. A /0 is not allowed."
  }
}

variable "container_port" {
  description = "Host TCP port published by Docker Compose for the quiz API."
  type        = number
  nullable    = false
  default     = 8000

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535 && floor(var.container_port) == var.container_port && var.container_port != 22
    error_message = "Use a whole TCP port from 1 to 65535 other than 22."
  }
}

variable "instance_type" {
  description = "x86-64 EC2 instance type available in the selected region."
  type        = string
  nullable    = false
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Optional region-specific Ubuntu 24.04 amd64 AMI ID for a repeatable rebuild."
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Local path to your OpenSSH public key (.pub)."
  type        = string
  nullable    = false
  default     = "~/.ssh/somaquiz.pub"
}

variable "additional_ssh_public_key_paths" {
  description = "Local OpenSSH public key files to authorize alongside the EC2 launch key."
  type        = set(string)
  default     = []
  nullable    = false
}
