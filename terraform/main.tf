locals {
  service_name = "${var.app_name}-${var.environment}"
  azs          = slice(sort(data.aws_availability_zones.available.names), 0, 2)
  operator_keys = [
    for path in sort(tolist(var.additional_ssh_public_key_paths)) : trimspace(file(pathexpand(path)))
  ]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "network" {
  source = "./modules/networking"

  name               = local.service_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  ssh_cidrs          = setunion(var.additional_ssh_cidrs, toset([var.ssh_cidr]))
  web_cidrs          = var.web_cidrs
  app_port           = var.container_port
}

module "registry" {
  source = "./modules/registry"

  name         = local.service_name
  force_delete = var.force_delete_ecr
}

module "host" {
  source = "./modules/compute"

  name                       = local.service_name
  app_subnet_id              = module.network.app_subnet_id
  bastion_subnet_id          = module.network.public_subnet_ids[0]
  app_security_group_id      = module.network.app_security_group_id
  bastion_security_group_id  = module.network.bastion_security_group_id
  app_instance_type          = var.app_instance_type
  bastion_instance_type      = var.bastion_instance_type
  ami_id                     = var.ami_id
  ssh_public_key             = trimspace(file(pathexpand(var.ssh_public_key_path)))
  additional_ssh_public_keys = local.operator_keys
  ecr_repository_arn         = module.registry.repository_arn
}

module "database" {
  source = "./modules/database"

  name                  = local.service_name
  subnet_ids            = module.network.database_subnet_ids
  vpc_id                = module.network.vpc_id
  app_security_group_id = module.network.app_security_group_id
  instance_class        = var.database_instance_class
  allocated_storage     = var.database_storage_gb
  database_name         = var.database_name
  database_username     = var.database_username
  deletion_protection   = var.database_deletion_protection
}

module "edge" {
  source = "./modules/edge"

  name              = local.service_name
  public_subnet_ids = module.network.public_subnet_ids
  vpc_id            = module.network.vpc_id
  security_group_id = module.network.alb_security_group_id
  instance_id       = module.host.instance_id
  app_port          = var.container_port
}
