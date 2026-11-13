variable "name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zone" {
  type    = string
  default = null
}

variable "ssh_cidr" {
  type = string
}

variable "additional_ssh_cidrs" {
  type    = set(string)
  default = []
}

variable "app_cidrs" {
  type = set(string)
}

variable "container_port" {
  type = number
}

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.app.id
  availability_zone = var.availability_zone
  cidr_block        = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 0)

  tags = { Name = "${var.name}-public" }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id

  tags = { Name = var.name }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Leave the VPC's default security group closed.
resource "aws_default_security_group" "closed" {
  vpc_id = aws_vpc.app.id
}

resource "aws_security_group" "host" {
  name        = "${var.name}-host"
  description = "SomaQuiz host traffic"
  vpc_id      = aws_vpc.app.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.host.id
  description       = "SSH from the operator"
  cidr_ipv4         = var.ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "additional_ssh" {
  for_each = setsubtract(var.additional_ssh_cidrs, [var.ssh_cidr])

  security_group_id = aws_security_group.host.id
  description       = "SSH from an additional operator"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each = var.app_cidrs

  security_group_id = aws_security_group.host.id
  description       = "Quiz API from an approved network"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.container_port
  to_port           = var.container_port
}

resource "aws_vpc_security_group_egress_rule" "web" {
  for_each = {
    "80"  = "Ubuntu package mirrors"
    "443" = "HTTPS updates and container registries"
  }

  security_group_id = aws_security_group.host.id
  description       = each.value
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.key)
  to_port           = tonumber(each.key)
}

output "vpc_id" {
  value = aws_vpc.app.id
}

output "subnet_id" {
  value      = aws_subnet.public.id
  depends_on = [aws_route_table_association.public]
}

output "security_group_id" {
  value = aws_security_group.host.id
}
