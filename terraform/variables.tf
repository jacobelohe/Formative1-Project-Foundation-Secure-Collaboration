variable "aws_region" {
  description = "AWS region for the stack."
  type        = string
  nullable    = false
}

variable "environment" {
  description = "Environment name used in resource tags."
  type        = string
  default     = "development"
}

variable "app_name" {
  description = "Application name used in resource tags."
  type        = string
  default     = "somaquiz"
}

variable "vpc_cidr" {
  description = "VPC CIDR split into five /24 public and private subnets."
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr)) && try(contains(range(16, 22), tonumber(split("/", var.vpc_cidr)[1])), false)
    error_message = "Use an IPv4 CIDR from /16 through /21 to fit the required subnet layout."
  }
}

variable "ssh_cidr" {
  description = "Operator public IPv4 address allowed to SSH to the bastion, in /32 form."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_cidr)) && endswith(var.ssh_cidr, "/32")
    error_message = "Use one public IPv4 address in /32 notation."
  }
}

variable "additional_ssh_cidrs" {
  description = "Additional operator public IPv4 addresses allowed to SSH to the bastion."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.additional_ssh_cidrs : try(can(cidrnetmask(cidr)) && endswith(cidr, "/32"), false)])
    error_message = "Use one public IPv4 address in /32 notation per additional operator."
  }
}

variable "web_cidrs" {
  description = "IPv4 CIDRs allowed to reach the public HTTP load balancer."
  type        = set(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.web_cidrs : can(cidrnetmask(cidr))])
    error_message = "Use valid IPv4 CIDRs for public web access."
  }
}

variable "container_port" {
  description = "Host TCP port published by Docker Compose and served by the load balancer."
  type        = number
  default     = 8000

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535 && floor(var.container_port) == var.container_port && var.container_port != 22
    error_message = "Use a whole TCP port from 1 to 65535 other than 22."
  }
}

variable "app_instance_type" {
  description = "EC2 instance type for the private application server."
  type        = string
  default     = "t3.micro"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the public SSH bastion."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Optional Ubuntu 24.04 amd64 AMI ID for the selected region."
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Local path to the OpenSSH public key installed on both instances."
  type        = string
  default     = "~/.ssh/somaquiz.pub"
}

variable "additional_ssh_public_key_paths" {
  description = "Local public-key paths for additional SSH operators."
  type        = set(string)
  default     = []
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "somaquiz"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "Use a PostgreSQL database name beginning with a letter and containing only letters, digits or underscores."
  }
}

variable "database_username" {
  description = "RDS master username; RDS generates and stores its password in Secrets Manager."
  type        = string
  default     = "somaquiz_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_username))
    error_message = "Use a PostgreSQL username beginning with a letter and containing only letters, digits or underscores."
  }
}

variable "database_instance_class" {
  description = "RDS instance class for the managed PostgreSQL database."
  type        = string
  default     = "db.t3.micro"
}

variable "database_storage_gb" {
  description = "Encrypted PostgreSQL storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.database_storage_gb >= 20 && var.database_storage_gb <= 1000
    error_message = "Use database storage between 20 and 1000 GiB."
  }
}

variable "database_deletion_protection" {
  description = "Prevent database deletion; turn off only for an intentional lab cleanup."
  type        = bool
  default     = false
}

variable "force_delete_ecr" {
  description = "Allow Terraform to delete an ECR repository that still contains images."
  type        = bool
  default     = false
}
