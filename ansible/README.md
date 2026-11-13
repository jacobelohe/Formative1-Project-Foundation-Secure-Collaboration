# Ansible Server Configuration and Application Deployment

This directory contains Ansible automation to configure, secure, and deploy the containerized SomaQuiz application onto the server provisioned by Terraform.

---

## Directory Structure

```text
ansible/
├── ansible.cfg
├── inventory.ini
├── playbook.yml
├── README.md
└── templates/
    └── env.j2
```

---

## Requirements and Prerequisites

Before running the playbook, ensure the following tools and access requirements are met:

- Ansible 2.14 or newer installed locally
- SSH access to the provisioned server with an authorized public key
- Python 3 installed on both local machine and target server
- Target host running Ubuntu 22.04 LTS or compatible Debian-based distribution

---

## Inventory Configuration

Edit `ansible/inventory.ini` and replace the placeholder values with your provisioned server details:

```ini
[webservers]
server1 ansible_host=YOUR_SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

---

## Playbook Execution Steps

### 1. Test Server Connectivity

```bash
ansible all -i inventory.ini -m ping
```

### 2. Verify Playbook Syntax

```bash
ansible-playbook -i inventory.ini --syntax-check playbook.yml
```

### 3. Dry-Run Execution (Check Mode)

```bash
ansible-playbook -i inventory.ini --check playbook.yml
```

### 4. Execute Full Playbook

```bash
ansible-playbook -i inventory.ini playbook.yml
```

---

## What the Playbook Configures

1. **System Updates**:
   - Updates APT package caches and upgrades installed packages to the latest stable versions.

2. **Security Hardening**:
   - Installs and enables UFW firewall and Fail2ban.
   - Sets default incoming policy to deny and outgoing policy to allow.
   - Permits incoming rate-limited SSH traffic on port 22.
   - Permits incoming application traffic on port 8000.
   - Enforces SSH daemon hardening by disabling root login, disabling password authentication, and disabling empty passwords.

3. **Runtime Dependencies**:
   - Configures official Docker GPG keyrings and APT repositories.
   - Installs Docker Engine, Docker CLI, containerd, and Docker Compose plugin.
   - Starts and enables the Docker daemon on system boot.
   - Adds the target user to the `docker` group.

4. **Application Deployment**:
   - Prepares application directory at `/opt/somaquiz`.
   - Transfers application manifests (`docker-compose.yml`, `Dockerfile`, source code).
   - Generates `.env` from template with configurable runtime parameters.
   - Builds and launches the containerized application via Docker Compose.
   - Validates live application availability against the `/health` endpoint.

---

## Post-Deployment Verification

### Check UFW Firewall Status

```bash
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP "sudo ufw status verbose"
```

### Check SSH Hardening

```bash
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP "sudo sshd -T | grep -E 'permitrootlogin|passwordauthentication'"
```

### Check Docker Service and Containers

```bash
ssh -i ~/.ssh/id_rsa ubuntu@YOUR_SERVER_IP "docker ps"
```

### Check Application Health Endpoint

```bash
curl http://YOUR_SERVER_IP:8000/health
```

