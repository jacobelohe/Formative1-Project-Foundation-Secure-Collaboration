mock_provider "aws" {
  mock_data "aws_ec2_instance_type_offerings" {
    defaults = {
      locations = ["us-east-1b", "us-east-1a"]
    }
  }

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
      output.container_port == 8000 &&
      output.ansible_vars.app_port == 8000 &&
      output.ansible_vars.app_bind_address == "127.0.0.1"
    )
    error_message = "The stack must expose the host address, SSH user and API port."
  }
}

run "handoff_with_direct_app_access" {
  command = plan

  variables {
    app_cidrs      = ["203.0.113.20/32"]
    container_port = 8080
  }

  assert {
    condition     = output.ansible_vars.app_port == 8080 && output.ansible_vars.app_bind_address == "0.0.0.0"
    error_message = "Ansible must publish the configured host port when direct access is enabled."
  }
}

run "reject_public_ingress" {
  command = plan

  variables {
    ssh_cidr             = "0.0.0.0/0"
    additional_ssh_cidrs = ["203.0.113.0/24"]
    app_cidrs            = ["0.0.0.0/0"]
  }

  expect_failures = [var.ssh_cidr, var.additional_ssh_cidrs, var.app_cidrs]
}
