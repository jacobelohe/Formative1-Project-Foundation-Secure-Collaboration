mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      insecure_value = "ami-0123456789abcdef0"
    }
  }

  mock_resource "aws_instance" {
    defaults = {
      public_ip  = "198.51.100.42"
      private_ip = "10.42.0.10"
    }
  }
}

variables {
  aws_region          = "us-east-1"
  ssh_cidr            = "198.51.100.10/32"
  ssh_public_key_path = "tests/fixtures/operator.pub"
}

run "ansible_handoff" {
  command = apply

  assert {
    condition = (
      output.public_ip == "198.51.100.42" &&
      output.private_ip == "10.42.0.10" &&
      output.ssh_user == "ubuntu" &&
      output.container_port == 8000
    )
    error_message = "The stack must expose the host address, SSH user and API port."
  }
}

run "reject_public_ingress" {
  command = plan

  variables {
    ssh_cidr  = "0.0.0.0/0"
    app_cidrs = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_cidr, var.app_cidrs]
}
