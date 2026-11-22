# Configure the SomaQuiz EC2 host

This playbook targets the Ubuntu 24.04 amd64 instance provisioned by Terraform. The roles configure UFW, SSH and Fail2ban, install Docker Engine and Compose, then build and verify the quiz API. The EC2 security group controls direct access to the Docker-published port.

## Controller setup

Run Ansible from Linux, macOS, or Ubuntu on WSL. Use Python 3.12 or later and Ansible Core 2.20 or later. Run commands from this directory unless noted.

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install 'ansible-core>=2.20,<2.22' 'boto3>=1.35'
ansible-galaxy collection install -r requirements.yml
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
```

The EC2 SSH security group must allow TCP 22 from the controller's public IPv4 address. Terraform must install the matching public key on the instance. Keep the private key on the controller and load it into `ssh-agent` if it has a passphrase. Verify the server's SSH host fingerprint before accepting it on first connection.

Keep SSH connection reuse enabled when running the playbook. The UFW SSH rate limit can reject repeated new connections during deployment.

## Build the inventory

After Terraform applies, take `aws_region`, `instance_id`, `public_ip` and `ssh_user` from `terraform output`. In the Terraform directory, export the application port and bind address for Ansible.

```bash
terraform output -json ansible_vars > ../ansible/.env.ansible.json
```

If using PowerShell, write UTF-8 without a byte-order mark so Ansible can read the file.

```powershell
$json = terraform output -json ansible_vars
[IO.File]::WriteAllLines((Join-Path (Get-Location) '../ansible/.env.ansible.json'), $json, [Text.UTF8Encoding]::new($false))
```

**Dynamic inventory.** Copy the template locally, then replace the region and instance ID placeholders with the Terraform outputs. Use an AWS profile available to the Ansible controller in the same account, with read access for `ec2:DescribeInstances`. On WSL, the profile must be accessible from Linux. The instance ID keeps the inventory scoped to one host while the plugin discovers its current public IP.

```bash
cp inventory/somaquiz.aws_ec2.yml .env.somaquiz.aws_ec2.yml
export AWS_PROFILE=your-discovery-profile
inventory=.env.somaquiz.aws_ec2.yml
ansible-inventory -i "$inventory" --graph
```

Confirm the graph contains your instance under `webservers`. The playbook stops if the inventory does not identify exactly one server. If the controller only has SSH access, copy `inventory.ini` to `.env.inventory.ini`, replace `YOUR_SERVER_IP` with the public IP, and set `inventory=.env.inventory.ini` for the commands below. Local files beginning with `.env.` are Git-ignored.

## Deploy and verify

Set `key` to the path to the controller's private key. First verify connectivity and check the playbook syntax.

```bash
key="$HOME/.ssh/somaquiz"
ansible-playbook -i "$inventory" --syntax-check playbook.yml
ansible webservers -i "$inventory" --private-key "$key" -m ansible.builtin.ping
```

Run the playbook, test a fresh SSH connection, and repeat the same playbook command. The first run waits for a healthy container and verifies the response from `/health`. The second run should leave a healthy, unchanged deployment in place. APT cache refreshes can register a change after the cache expires.

```bash
ansible-playbook -i "$inventory" --private-key "$key" -e @.env.ansible.json playbook.yml
ssh -i "$key" ubuntu@YOUR_SERVER_IP 'sudo ufw status && sudo fail2ban-client status sshd && sudo sshd -T | grep -E "^(permitrootlogin|passwordauthentication|authenticationmethods) "'
```

By default, the API binds to the instance's loopback interface. Open an SSH tunnel using the port from `terraform output -raw container_port`. The example uses the default port on both ends.

```bash
ssh -i "$key" -N -L 8000:127.0.0.1:8000 ubuntu@YOUR_SERVER_IP
```

From a second terminal, run `curl -fsS http://127.0.0.1:8000/health`. If Terraform has approved `app_cidrs`, the exported settings instead publish the port on the instance's interfaces, with the security group restricting the allowed sources.

If the deployment fails, check the failed task and Compose status printed by the playbook. Use the commands below on the instance to inspect the containers. The deployment leaves the Compose data volume in place for a retry.

```bash
cd /opt/somaquiz
sudo docker compose -f docker-compose.yml -f compose.override.yml ps -a
sudo docker compose -f docker-compose.yml -f compose.override.yml logs --tail=50 quiz-api
```
