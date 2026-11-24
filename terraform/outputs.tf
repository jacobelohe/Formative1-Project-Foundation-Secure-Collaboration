output "application_url" {
  description = "Public HTTP URL served by the application load balancer."
  value       = module.edge.url
}

output "load_balancer_dns_name" {
  description = "DNS name of the public application load balancer."
  value       = module.edge.dns_name
}

output "vpc_id" {
  description = "VPC containing the private application and database tiers."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets used by the bastion and application load balancer."
  value       = module.network.public_subnet_ids
}

output "app_subnet_id" {
  description = "Private subnet containing the application EC2 instance."
  value       = module.network.app_subnet_id
}

output "database_subnet_ids" {
  description = "Isolated subnets assigned to RDS."
  value       = module.network.database_subnet_ids
}

output "security_group_ids" {
  description = "Security groups for bastion, application, load balancer and database."
  value = {
    bastion  = module.network.bastion_security_group_id
    app      = module.network.app_security_group_id
    web      = module.network.alb_security_group_id
    database = module.database.security_group_id
  }
}

output "app_instance_id" {
  description = "EC2 instance ID for Ansible and operations."
  value       = module.host.instance_id
}

output "app_private_ip" {
  description = "Private address for Ansible through the bastion."
  value       = module.host.private_ip
}

output "bastion_instance_id" {
  description = "Public jump host instance ID."
  value       = module.host.bastion_id
}

output "bastion_public_ip" {
  description = "SSH entry point restricted to configured operator CIDRs."
  value       = module.host.bastion_public_ip
}

output "ssh_user" {
  description = "Ubuntu SSH account used on the app and bastion hosts."
  value       = "ubuntu"
}

output "container_port" {
  description = "Port published by the application container for the load balancer."
  value       = var.container_port
}

output "ecr_repository_url" {
  description = "Private ECR repository used for application image releases."
  value       = module.registry.repository_url
}

output "database_endpoint" {
  description = "Private RDS endpoint; not reachable from the public internet."
  value       = module.database.endpoint
}

output "database_port" {
  description = "PostgreSQL port accepted only from the application security group."
  value       = module.database.port
}

output "database_master_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret; the password is not output."
  value       = module.database.master_secret_arn
}

output "ansible_vars" {
  description = "Non-secret app and bastion values for the Ansible handoff."
  value = {
    app_port         = var.container_port
    app_bind_address = "0.0.0.0"
    app_host         = module.host.private_ip
    bastion_host     = module.host.bastion_public_ip
    ssh_user         = "ubuntu"
  }
}

output "aws_region" {
  description = "Region where the stack is provisioned."
  value       = var.aws_region
}

output "environment" {
  description = "Environment name used by this stack."
  value       = var.environment
}

output "github_deploy_role_arn" {
  description = "IAM role that GitHub Actions assumes through OIDC."
  value       = module.cicd.role_arn
}

output "database_name" {
  description = "Initial PostgreSQL database name."
  value       = var.database_name
}
