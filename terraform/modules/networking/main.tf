variable "name" { type = string }
variable "vpc_cidr" { type = string }
variable "availability_zones" { type = list(string) }
variable "ssh_cidrs" { type = set(string) }
variable "web_cidrs" { type = set(string) }
variable "app_port" { type = number }

resource "aws_vpc" "app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.app.id
  availability_zone       = var.availability_zones[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 0)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.app.id
  availability_zone       = var.availability_zones[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 1)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-public-b" }
}

resource "aws_subnet" "app" {
  vpc_id                  = aws_vpc.app.id
  availability_zone       = var.availability_zones[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 2)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-app-private" }
}

resource "aws_subnet" "database_a" {
  vpc_id                  = aws_vpc.app.id
  availability_zone       = var.availability_zones[0]
  cidr_block              = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 3)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-data-private-a" }
}

resource "aws_subnet" "database_b" {
  vpc_id                  = aws_vpc.app.id
  availability_zone       = var.availability_zones[1]
  cidr_block              = cidrsubnet(var.vpc_cidr, 24 - tonumber(split("/", var.vpc_cidr)[1]), 4)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-data-private-b" }
}

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = var.name }
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

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "${var.name}-app-private" }
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.app.id
  tags   = { Name = "${var.name}-data-isolated" }
}

resource "aws_route_table_association" "database_a" {
  subnet_id      = aws_subnet.database_a.id
  route_table_id = aws_route_table.database.id
}

resource "aws_route_table_association" "database_b" {
  subnet_id      = aws_subnet.database_b.id
  route_table_id = aws_route_table.database.id
}

resource "aws_default_security_group" "closed" {
  vpc_id = aws_vpc.app.id
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-bastion"
  description = "Bastion SSH access"
  vpc_id      = aws_vpc.app.id
  egress      = []
  tags        = { Name = "${var.name}-bastion" }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "Private application host"
  vpc_id      = aws_vpc.app.id
  egress      = []
  tags        = { Name = "${var.name}-app" }
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-web"
  description = "Public HTTP entry point"
  vpc_id      = aws_vpc.app.id
  egress      = []
  tags        = { Name = "${var.name}-web" }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each          = var.ssh_cidrs
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from an approved operator"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_app_ssh" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "SSH to the private application host"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh" {
  security_group_id            = aws_security_group.app.id
  description                  = "SSH only through the bastion"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "app_web" {
  security_group_id            = aws_security_group.app.id
  description                  = "Application requests from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Temporary access for Ubuntu packages and ECR image pulls through the NAT gateway.
#trivy:ignore:AWS-0104:exp:2026-12-13
resource "aws_vpc_security_group_egress_rule" "app_web" {
  for_each          = toset(["80", "443"])
  security_group_id = aws_security_group.app.id
  description       = "Package and container registry access through NAT"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
}

resource "aws_vpc_security_group_egress_rule" "app_database" {
  security_group_id = aws_security_group.app.id
  description       = "PostgreSQL within the VPC"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each          = var.web_cidrs
  security_group_id = aws_security_group.alb.id
  description       = "Public web traffic"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "alb_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward HTTP to the private app host"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

output "vpc_id" { value = aws_vpc.app.id }
output "public_subnet_ids" { value = [aws_subnet.public.id, aws_subnet.public_b.id] }
output "app_subnet_id" { value = aws_subnet.app.id }
output "database_subnet_ids" { value = [aws_subnet.database_a.id, aws_subnet.database_b.id] }
output "bastion_security_group_id" { value = aws_security_group.bastion.id }
output "bastion_security_group_arn" { value = aws_security_group.bastion.arn }
output "app_security_group_id" { value = aws_security_group.app.id }
output "alb_security_group_id" { value = aws_security_group.alb.id }
