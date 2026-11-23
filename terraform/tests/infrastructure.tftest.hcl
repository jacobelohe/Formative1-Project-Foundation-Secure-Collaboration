mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-east-1a", "us-east-1b"] }
  }

  mock_data "aws_ssm_parameter" {
    defaults = { insecure_value = "ami-0123456789abcdef0" }
  }

  mock_resource "aws_instance" {
    defaults = {
      public_ip  = "198.51.100.42"
      private_ip = "10.42.2.10"
    }
  }

  mock_resource "aws_db_instance" {
    defaults = {
      address = "db.example.test"
      port    = 5432
      master_user_secret = [{
        secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:somaquiz-db"
        secret_status = "active"
      }]
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/somaquiz/abc"
      dns_name = "somaquiz.example.test"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/somaquiz/abc"
    }
  }
}

variables {
  aws_region          = "us-east-1"
  ssh_cidr            = "198.51.100.10/32"
  ssh_public_key_path = "tests/fixtures/operator.pub"
}

run "private_stack_handoff" {
  command = apply

  assert {
    condition = (
      output.app_private_ip == "10.42.2.10" &&
      output.bastion_public_ip == "198.51.100.42" &&
      output.ssh_user == "ubuntu" &&
      output.container_port == 8000 &&
      output.ansible_vars.app_bind_address == "0.0.0.0" &&
      output.ansible_vars.app_host == output.app_private_ip
    )
    error_message = "Expose private app and bastion connection details without publishing the app host."
  }
}

run "reject_open_ssh" {
  command = plan

  variables {
    ssh_cidr = "0.0.0.0/0"
  }

  expect_failures = [var.ssh_cidr]
}
