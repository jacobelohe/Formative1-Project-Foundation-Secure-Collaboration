output "vpc_id" {
  description = "ID of the SomaQuiz VPC."
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "ID of the public subnet."
  value       = module.network.subnet_id
}

output "security_group_id" {
  description = "ID of the instance security group."
  value       = module.network.security_group_id
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = module.host.instance_id
}

output "public_ip" {
  description = "Public IPv4 address for SSH and the Ansible inventory."
  value       = module.host.public_ip
}

output "private_ip" {
  description = "Private IPv4 address inside the VPC."
  value       = module.host.private_ip
}

output "ssh_user" {
  description = "Login user on the official Ubuntu AMI."
  value       = "ubuntu"
}

output "container_port" {
  description = "Host port for the quiz API after deployment."
  value       = var.container_port
}

output "aws_region" {
  description = "AWS region where the stack runs."
  value       = var.aws_region
}

output "environment" {
  description = "Deployment name used in resource tags."
  value       = var.environment
}

output "app_name" {
  description = "Application name used in resource tags."
  value       = var.app_name
}

output "service_name" {
  description = "Prefix used for resource names."
  value       = local.service_name
}
