mock_provider "aws" {}

variables {
  name           = "somaquiz-test"
  vpc_cidr       = "10.42.0.0/16"
  ssh_cidr       = "198.51.100.10/32"
  app_cidrs      = []
  container_port = 8000
}

run "default_ingress" {
  command = plan

  module {
    source = "./modules/network"
  }

  assert {
    condition = (
      aws_subnet.public.cidr_block == "10.42.0.0/24" &&
      aws_vpc_security_group_ingress_rule.ssh.cidr_ipv4 == var.ssh_cidr &&
      aws_vpc_security_group_ingress_rule.ssh.from_port == 22 &&
      length(aws_vpc_security_group_ingress_rule.app) == 0
    )
    error_message = "Use the first /24, restrict SSH to the operator and keep the API closed by default."
  }
}

run "approved_app_ingress" {
  command = plan

  module {
    source = "./modules/network"
  }

  variables {
    app_cidrs = ["203.0.113.20/32"]
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app["203.0.113.20/32"].from_port == var.container_port
    error_message = "An approved source must be able to reach the configured API port."
  }
}
