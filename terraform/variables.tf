variable "aws_region" {
  type    = string
  default = "af-south-1"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "app_name" {
  type    = string
  default = "somaquiz"
}

variable "container_port" {
  type    = number
  default = 8000
}
