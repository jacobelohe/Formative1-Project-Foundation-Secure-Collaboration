variable "name" { type = string }
variable "subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "app_security_group_id" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage" { type = number }
variable "database_name" { type = string }
variable "database_username" { type = string }
variable "deletion_protection" { type = bool }

resource "aws_security_group" "database" {
  name        = "${var.name}-database"
  description = "PostgreSQL access from the private app host only"
  vpc_id      = var.vpc_id
  egress      = []
  tags        = { Name = "${var.name}-database" }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id            = aws_security_group.database.id
  description                  = "PostgreSQL from the application security group"
  referenced_security_group_id = var.app_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.name}-database"
  subnet_ids = var.subnet_ids
  tags       = { Name = "${var.name}-database" }
}

resource "aws_db_instance" "database" {
  identifier                  = "${var.name}-database"
  engine                      = "postgres"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = var.database_name
  username                    = var.database_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.database.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  publicly_accessible         = false
  backup_retention_period     = 1
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = true
  auto_minor_version_upgrade  = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = { Name = "${var.name}-database" }
}

output "endpoint" { value = aws_db_instance.database.address }
output "port" { value = aws_db_instance.database.port }
output "resource_id" { value = aws_db_instance.database.resource_id }
output "master_secret_arn" { value = aws_db_instance.database.master_user_secret[0].secret_arn }
output "security_group_id" { value = aws_security_group.database.id }
