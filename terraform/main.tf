locals {
  service_name = "${var.app_name}-${var.environment}"
}

data "aws_ec2_instance_type_offerings" "host" {
  location_type = "availability-zone"

  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }

  lifecycle {
    postcondition {
      condition     = length(self.locations) > 0
      error_message = "The selected region does not offer this instance type."
    }
  }
}

module "network" {
  source = "./modules/network"

  name                 = local.service_name
  vpc_cidr             = var.vpc_cidr
  availability_zone    = try(sort(data.aws_ec2_instance_type_offerings.host.locations)[0], null)
  ssh_cidr             = var.ssh_cidr
  additional_ssh_cidrs = var.additional_ssh_cidrs
  app_cidrs            = var.app_cidrs
  container_port       = var.container_port
}

module "host" {
  source = "./modules/host"

  name              = local.service_name
  subnet_id         = module.network.subnet_id
  security_group_id = module.network.security_group_id
  instance_type     = var.instance_type
  ami_id            = var.ami_id
  ssh_public_key    = trimspace(file(pathexpand(var.ssh_public_key_path)))
  additional_ssh_public_keys = [
    for path in sort(tolist(var.additional_ssh_public_key_paths)) : trimspace(file(pathexpand(path)))
  ]
}
