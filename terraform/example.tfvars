# Copy to terraform.tfvars locally and replace the two required values.
aws_region = "REPLACE_WITH_YOUR_AWS_REGION"
ssh_cidr   = "198.51.100.10/32" # Your current public IPv4 address.

environment = "development"
app_name    = "somaquiz"

# Keep only teammates who need bastion access; each address must end in /32.
# additional_ssh_cidrs = ["203.0.113.20/32"]

# Optional key files, corresponding to the additional operator CIDRs above.
# additional_ssh_public_key_paths = ["~/.ssh/teammate.pub"]

# Optional: restrict the public site to selected IPv4 CIDRs. Default is public HTTP.
# web_cidrs = ["198.51.100.10/32"]

# These small defaults are intended for a class lab. The NAT gateway, ALB,
# two EC2 instances and RDS database incur AWS charges while provisioned.
# Review the Terraform plan and your AWS pricing before applying.
# app_instance_type          = "t3.micro"
# bastion_instance_type      = "t3.micro"
# database_instance_class    = "db.t3.micro"
# database_deletion_protection = true
# force_delete_ecr            = false
