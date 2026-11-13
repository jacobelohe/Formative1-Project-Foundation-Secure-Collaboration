# SomaQuiz infrastructure

Terraform creates one VPC, one public subnet and an Ubuntu 24.04 EC2 instance for the SomaQuiz quiz API. The network module manages the subnet, internet gateway, routing and security groups. The host module manages the EC2 instance and imports your SSH public key. [Canonical Ubuntu AMI lookup](https://documentation.ubuntu.com/aws/aws-how-to/instances/build-cloudformation-templates/)

The host requires IMDSv2 and uses an encrypted 16 GiB gp3 root volume. SSH is allowed from one public IPv4 address. Direct access to the quiz API is off by default. Outbound TCP ports 80 and 443 support OS updates and container pulls.

## Prerequisites

- Terraform 1.7 or newer, AWS CLI and OpenSSH.
- An authenticated AWS profile with permissions to manage the EC2 and VPC resources and read Canonical's public AMI parameter through `ssm:GetParameter`.
- A region enabled in your AWS account that offers the selected x86-64 instance type. EC2, EBS and the public IPv4 address can incur charges.

## Initialize and validate

Run these commands in PowerShell from the repository root. Create the SSH key only if you do not already have a public key to use. When prompted, set a passphrase for the private key.

```powershell
New-Item -ItemType Directory -Force "$HOME/.ssh" | Out-Null
ssh-keygen -t ed25519 -f "$HOME/.ssh/somaquiz"

cd terraform
Copy-Item example.tfvars terraform.tfvars
notepad terraform.tfvars
```

Set `aws_region` to your chosen AWS region and `ssh_cidr` to the public IPv4 address of the machine running SSH or Ansible, followed by `/32`. If you use an existing key, set `ssh_public_key_path` to its `.pub` file. Keep the private key on your machine.

`container_port` defaults to `8000` to match the repository's Docker Compose host port. If you change it, use the same host port when deploying the container. If you need direct HTTP for a demo, set `app_cidrs` to the approved source CIDRs. For example, `app_cidrs = ["198.51.100.10/32"]` illustrates the format. Replace that address before use.

```powershell
terraform init
terraform fmt -check -recursive
terraform validate
terraform test
```

The tests use a mocked AWS provider. They check the network rules and the Ansible handoff outputs without making AWS API calls.

## Plan and apply

Use the name of your configured profile in place of `your-profile`. You can omit the profile assignment when using the AWS CLI default profile. Verify that the AWS CLI reports the intended account before proceeding.

If your CLI uses a browser-based `aws login` session, the pinned Terraform AWS provider can use it through a separate local profile. Add this section to `~/.aws/config`. Replace `default` in the command if your browser login uses a named profile. Then use `somaquiz-terraform` as `AWS_PROFILE` below. [AWS CLI credential export](https://docs.aws.amazon.com/cli/latest/reference/configure/export-credentials.html)

```ini
[profile somaquiz-terraform]
credential_process = aws configure export-credentials --profile default --format process
```

```powershell
$env:AWS_PROFILE = "your-profile"
aws sts get-caller-identity

terraform plan '-out=somaquiz.tfplan'
terraform show somaquiz.tfplan
terraform apply somaquiz.tfplan
terraform output
```

Use the saved plan only after reviewing the proposed resources. If you edit inputs after planning, create a new plan. Re-running `terraform plan` with the same inputs should show no changes unless a resource drifted or the latest Ubuntu AMI changed. Set `ami_id` to an approved Ubuntu 24.04 amd64 AMI in the selected region if you want to pin the image and control when the instance is replaced.

## Connect and hand off to Ansible

```powershell
$vmIp = terraform output -raw public_ip
$vmUser = terraform output -raw ssh_user
ssh -i "$HOME/.ssh/somaquiz" "$vmUser@$vmIp"
```

Use the corresponding private key path if you selected a different key. Allow time for EC2 and SSH to start. If SSH times out, check the EC2 instance status and confirm that `ssh_cidr` matches your current public IPv4 address.

For Ansible, pass along `aws_region` and `instance_id` for dynamic discovery, or `public_ip` and `ssh_user` for the static inventory. Export the port and bind address with `terraform output -json ansible_vars`. Update the instance ID after a replacement, or refresh the public IP in the static inventory after a stop/start. [Ansible setup and verification](../ansible/README.md)

Once Part 2 is deployed, access the API without opening its port to the internet. Keep this SSH session open, then run `curl.exe http://127.0.0.1:8000/health` from another terminal.

```powershell
$port = terraform output -raw container_port
ssh -i "$HOME/.ssh/somaquiz" -N -L "8000:127.0.0.1:$port" "$vmUser@$vmIp"
```

## State and cleanup

This lab uses local Terraform state. Keep state and plan files private and retain the state until cleanup. The provider lockfile `.terraform.lock.hcl` pins the provider version for the team. The repository ignores the Terraform working directory, state, local variables and saved plans.

When you finish the lab, preview deletion and destroy the stack with the same AWS profile, inputs and state you used to create it. Destroying the instance also deletes its root volume.

```powershell
terraform plan -destroy
terraform destroy
```

For a shared environment, use a team-controlled encrypted and versioned remote backend with locking. [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
