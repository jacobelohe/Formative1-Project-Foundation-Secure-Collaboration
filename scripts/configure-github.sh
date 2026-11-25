#!/usr/bin/env bash
# Copy Terraform outputs into the GitHub "production" environment used by cd.yml.
# Run after every terraform apply that recreates the hosts, from an address in ssh_cidr.
#
# Usage: scripts/configure-github.sh PATH_TO_DEPLOY_PRIVATE_KEY
set -euo pipefail

key=${1:?Usage: scripts/configure-github.sh PATH_TO_DEPLOY_PRIVATE_KEY}
[ -r "$key" ] || { echo "Cannot read $key" >&2; exit 1; }
cd "$(dirname "$0")/.."

out() { terraform -chdir=terraform output -raw "$1"; }
set_var() { gh variable set "$1" --env production --body "$2"; }

# Read everything before changing GitHub, so a failure leaves the settings untouched.
role_arn=$(out github_deploy_role_arn)
region=$(out aws_region)
ecr_url=$(out ecr_repository_url)
bastion=$(out bastion_public_ip)
app=$(out app_private_ip)
app_port=$(out container_port)
app_url=$(out application_url)
db_host=$(out database_endpoint)
db_port=$(out database_port)
db_name=$(out database_name)
db_secret=$(out database_master_secret_arn)
bastion_sg=$(terraform -chdir=terraform output -json security_group_ids | jq -re .bastion)

# Pin the SSH host keys. The app key is read through the bastion because it has no public IP.
bastion_keys=$(ssh-keyscan -T 10 -t ed25519 "$bastion" 2>/dev/null)
[ -n "$bastion_keys" ] || { echo "No host key from $bastion. Is your address in ssh_cidr?" >&2; exit 1; }
known_hosts=$(mktemp)
trap 'rm -f "$known_hosts"' EXIT
printf '%s\n' "$bastion_keys" > "$known_hosts"
app_keys=$(ssh -i "$key" -o UserKnownHostsFile="$known_hosts" -o StrictHostKeyChecking=yes \
  "ubuntu@$bastion" ssh-keyscan -T 10 -t ed25519 "$app" 2>/dev/null)
[ -n "$app_keys" ] || { echo "No host key from $app through the bastion." >&2; exit 1; }

echo "Check these fingerprints against the EC2 console system logs:"
printf '%s\n%s\n' "$bastion_keys" "$app_keys" | ssh-keygen -lf -

# Only the protected main branch may use this environment, and so assume the AWS role.
gh api --silent -X PUT "repos/{owner}/{repo}/environments/production" \
  -F "deployment_branch_policy[protected_branches]=true" \
  -F "deployment_branch_policy[custom_branch_policies]=false"

gh secret set AWS_ROLE_ARN --env production --body "$role_arn"
gh secret set SSH_PRIVATE_KEY --env production < "$key"
printf '%s\n%s\n' "$bastion_keys" "$app_keys" | gh secret set SSH_KNOWN_HOSTS --env production

set_var AWS_REGION "$region"
set_var ECR_REPOSITORY_URL "$ecr_url"
set_var BASTION_HOST "$bastion"
set_var BASTION_SECURITY_GROUP_ID "$bastion_sg"
set_var APP_HOST "$app"
set_var APP_PORT "$app_port"
set_var APP_URL "$app_url"
set_var DB_HOST "$db_host"
set_var DB_PORT "$db_port"
set_var DB_NAME "$db_name"
set_var DB_SECRET_ARN "$db_secret"

echo "Done. The next merge to main deploys to $app_url"
