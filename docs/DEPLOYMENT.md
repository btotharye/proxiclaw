# Deployment Guide

Complete guide for deploying OpenClaw on Proxmox.

## Choosing Your Provisioning Approach

This project supports two approaches for creating the Proxmox VM. Both are valid — choose the one that fits your workflow:

| | **Terraform + Ansible** | **Ansible-only** |
|---|---|---|
| **VM Provisioning** | Terraform (state-tracked) | `community.general.proxmox_kvm` |
| **Configuration** | Ansible | Ansible |
| **State management** | ✅ `terraform.tfstate` tracks what was created | ❌ No built-in drift detection |
| **Destroy VMs** | `terraform destroy` | Manual via Proxmox UI/CLI |
| **Cloud-init / disk resize** | ✅ Full support via `bpg/proxmox` provider | ⚠️ Limited (basic cloud-init only) |
| **Recommended for** | Production, repeatable infra | Simpler setups, Terraform not available |

**Recommendation:** Use **Terraform + Ansible** if you want reproducible infrastructure with proper state tracking. Use **Ansible-only** if you prefer a single toolchain or Terraform is not available in your environment.

## Prerequisites

Before starting, ensure you have:

- [ ] Proxmox VE 7.0+ with API access configured
- [ ] Ubuntu 22.04 cloud-init template created
- [ ] Ansible installed on local machine
- [ ] SSH key pair generated (`~/.ssh/id_rsa`)
- [ ] For Terraform path: Terraform >= 1.0 installed

See [PROXMOX_SETUP.md](PROXMOX_SETUP.md) for detailed Proxmox preparation steps.

## Quick Start

### 1. Initial Setup

```bash
# Clone or navigate to the repository
cd proxiclaw

# Run setup script (installs dependencies and creates config files)
./scripts/setup.sh
```

### 2. Configure Application Settings

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
ansible_user: "ubuntu"
ansible_ssh_private_key_file: "~/.ssh/id_rsa"
openclaw_port: 18789
anthropic_api_key: "sk-ant-your-key-here"
```

---

## Option A: Terraform + Ansible (Recommended)

### Configure Proxmox Credentials

Edit `terraform/terraform.tfvars`:

```hcl
proxmox_host              = "192.168.1.100:8006"
proxmox_api_token_id      = "root@pam!terraform"
proxmox_api_token_secret  = "your-secret-token"
proxmox_node              = "pve"
template_name             = "9000"
vm_storage                = "local-zfs"
vm_network_bridge         = "vmbr0"
```

### Deploy

Full automated deployment:

```bash
./scripts/deploy.sh --full
# or: make deploy-full
```

Or step by step:

```bash
# Step 1: Create VM
./scripts/deploy.sh --terraform-only
# or: make deploy-vm

# Step 2: Configure and deploy OpenClaw
./scripts/deploy.sh --ansible-only
# or: make deploy-config
```

### Destroy Infrastructure

```bash
./scripts/deploy.sh --destroy
# or: make destroy
```

---

## Option B: Ansible-only (No Terraform)

Use this path when you want a single-tool workflow or Terraform is not available.

### Configure Proxmox Connection in group_vars

Edit `ansible/inventory/group_vars/all.yml` and fill in the Proxmox provisioning section:

```yaml
proxmox_api_host: "192.168.1.100"
proxmox_api_user: "root@pam"
proxmox_api_token_id: "terraform"
proxmox_api_token_secret: "your-secret"   # use ansible-vault for this!
proxmox_node: "pve"

vm_id: 150
vm_name: "openclaw-vm"
vm_template: "ubuntu-2204-cloudinit"
vm_cores: 4
vm_memory: 8192
vm_storage: "local-zfs"
ssh_public_key_file: "~/.ssh/id_rsa.pub"
```

Protect the token secret with Ansible Vault:

```bash
ansible-vault encrypt_string 'your-token-secret' --name proxmox_api_token_secret
# Paste the output into all.yml
```

### Install Required Collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### Provision and Configure

```bash
./scripts/deploy.sh --ansible-provision
# or: make provision-ansible
```

This runs `playbooks/provision-with-ansible.yml` which provisions the VM **and** runs the full configuration (common, docker, openclaw, openclaw-backup roles) in one step.

---

## Option C: Configuration Only (Existing VM)

If you already have Ubuntu installed on a VM:

```bash
# 1. Update inventory with your VM IP
cp ansible/inventory/hosts.example ansible/inventory/hosts
# Edit ansible/inventory/hosts

# 2. Run configuration playbook
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

## Customization

### Custom Docker Image

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
openclaw_docker_image: "your-registry/openclaw:v1.0"
```

### Firewall Rules

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
ufw_allow_ports:
  - "22"    # SSH
  - "443"   # HTTPS
  - "18789" # OpenClaw
```

## Verification

### Check VM Status

```bash
# SSH to Proxmox
ssh root@proxmox-host

# List VMs
qm list

# Check VM status
qm status <vmid>
```

### Check Application Status

```bash
# SSH to VM
ssh ubuntu@<vm-ip>

# Check Docker containers
cd /opt/openclaw && docker compose ps

# View logs
docker compose logs -f openclaw-gateway

# Check service health
cd /opt/openclaw && docker compose exec openclaw-gateway openclaw health
```

## Maintenance

### Update Application

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml --tags openclaw
```

### Restart Services

```bash
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart"
```

### View Logs

```bash
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 -f"
```

## Troubleshooting

### Terraform Issues

**VM creation fails**:

```bash
cd terraform
terraform plan  # Check for errors
terraform show  # View current state
```

**Can't connect to Proxmox**:

- Verify API token is correct
- Check firewall allows port 8006
- Ensure SSH agent has your key: `ssh-add -L`

### Ansible Issues

**Connection timeout**:

```bash
# Test SSH directly
ssh ubuntu@<vm-ip>

# Check inventory
ansible-inventory -i ansible/inventory/hosts --list

# Verbose output
ansible-playbook -vvv -i ansible/inventory/hosts playbooks/site.yml
```

### Using Ansible Vault for Secrets

```bash
# Create encrypted variables file
ansible-vault create ansible/inventory/group_vars/vault.yml

# Run with vault
ansible-playbook -i ansible/inventory/hosts playbooks/site.yml --ask-vault-pass
```

### Multiple Environments

Create separate inventory files:

```
ansible/inventory/
  ├── production/
  │   ├── hosts
  │   └── group_vars/
  ├── staging/
  │   ├── hosts
  │   └── group_vars/
```

Deploy to specific environment:

```bash
ansible-playbook -i ansible/inventory/production playbooks/site.yml
```

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs as described in [Maintenance](#maintenance)
3. Open an issue with error messages and steps to reproduce

