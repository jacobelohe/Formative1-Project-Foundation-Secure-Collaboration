mock_provider "aws" {}

variables {
  name               = "somaquiz-test"
  vpc_cidr           = "10.42.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  ssh_cidrs          = ["198.51.100.10/32"]
  web_cidrs          = ["0.0.0.0/0"]
  app_port           = 8000
}

run "segmented_private_network" {
  command = apply

  module {
    source = "./modules/networking"
  }

  assert {
    condition = (
      !aws_subnet.public.map_public_ip_on_launch &&
      !aws_subnet.public_b.map_public_ip_on_launch &&
      !aws_subnet.app.map_public_ip_on_launch &&
      aws_subnet.app.availability_zone == "us-east-1a" &&
      aws_subnet.database_b.availability_zone == "us-east-1b" &&
      length(output.public_subnet_ids) == 2 &&
      length(output.database_subnet_ids) == 2
    )
    error_message = "Subnets must not auto-assign public IPs; the app and database stay private and the edge spans two public zones."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.bastion_ssh["198.51.100.10/32"].from_port == 22 &&
      aws_vpc_security_group_ingress_rule.app_ssh.referenced_security_group_id == aws_security_group.bastion.id &&
      aws_vpc_security_group_ingress_rule.app_web.referenced_security_group_id == aws_security_group.alb.id &&
      aws_vpc_security_group_ingress_rule.alb_http["0.0.0.0/0"].from_port == 80
    )
    error_message = "SSH must use the bastion and app traffic must come through the public load balancer."
  }
}
