# Deploy SomaQuiz with Ansible

`deploy.yml` configures the private Ubuntu 24.04 application VM and deploys one image release to it. The CD pipeline runs it on every merge to `main`. You can also run it by hand.

| Role | What it does |
|---|---|
| `host_security` | UFW, Fail2ban and key-only SSH |
| `docker_runtime` | System packages, Docker Engine and the Compose plugin |
| `ecr_login` | Authenticates Docker to the private ECR registry with the VM's instance role |
| `somaquiz` | Pulls the image, runs `docker compose up -d`, checks `/ready`, rolls back on failure |

## Controller setup

Run Ansible from Linux, macOS, or Ubuntu on WSL, with Python 3.12 or later.

```bash
cd ansible
python3 -m venv .venv
source .venv/bin/activate
python -m pip install 'ansible-core>=2.20,<2.22'
ansible-galaxy collection install -r requirements.yml
```

The controller's public IPv4 address must be in `ssh_cidr` or `additional_ssh_cidrs`. Load the private key into the agent; both hops use it.

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/somaquiz
```

Host keys are checked on both hops. Connect once and compare the fingerprints with the EC2 console system log before accepting them:

```bash
ssh -J ubuntu@BASTION_PUBLIC_IP ubuntu@APP_PRIVATE_IP true
```

## Connection and release settings

`inventory.ini` and `group_vars/app_server.yml` read these values from the environment, so no address is committed. The VM has no public IP: `ansible_ssh_common_args` uses the bastion as the SSH proxy.

```bash
tf() { terraform -chdir=../terraform output -raw "$1"; }
export BASTION_HOST=$(tf bastion_public_ip) APP_HOST=$(tf app_private_ip) APP_PORT=$(tf container_port)
export AWS_REGION=$(tf aws_region) DB_HOST=$(tf database_endpoint) DB_PORT=$(tf database_port)
export DB_NAME=$(tf database_name) DB_SECRET_ARN=$(tf database_master_secret_arn)
export APP_IMAGE="$(tf ecr_repository_url):FULL_COMMIT_SHA"   # must already be in ECR
```

`inventory/somaquiz.aws_ec2.yml` is an optional dynamic inventory. It needs `boto3` and AWS read access; copy it to a Git-ignored `.env.somaquiz.aws_ec2.yml` and fill in the region and instance ID.

## Deploy and verify

```bash
ansible-playbook --syntax-check deploy.yml
ansible app_server -m ansible.builtin.ping
ansible-playbook deploy.yml
```

The playbook is idempotent: a second run with the same image leaves the running container alone. Keep SSH connection reuse enabled, because the UFW rate limit can reject many new connections.

The database password is never handled by Ansible. The container reads it from Secrets Manager with the instance role.

## Roll back

A failed deployment restores the image recorded in `/opt/somaquiz/.release` and still fails the run, so the pipeline turns red. To return to an older release on purpose, set `APP_IMAGE` to its tag and run the playbook. Reverting the pull request does the same through the pipeline.

## Troubleshoot on the VM

```bash
cd /opt/somaquiz
sudo docker compose ps -a
sudo docker compose logs --tail=50 quiz-api
```
