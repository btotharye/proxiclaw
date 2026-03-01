# Deployment Guide

Complete guide for deploying OpenClaw on Proxmox.

## Prerequisites

Before starting, ensure you have:

- [ ] Proxmox VE 7.0+ with API access configured
- [ ] Ubuntu 22.04 cloud-init template created
- [ ] Terraform installed on local machine
- [ ] Ansible installed on local machine
- [ ] SSH key pair generated (`~/.ssh/id_rsa`)

See [PROXMOX_SETUP.md](PROXMOX_SETUP.md) for detailed Proxmox preparation steps.

## Quick Start

### 1. Initial Setup

```bash
# Clone or navigate to the repository
cd openclaw

# Run setup script (installs dependencies and creates config files)
./scripts/setup.sh
```

### 2. Configure Proxmox Credentials

Edit `terraform/terraform.tfvars`:

```hcl
proxmox_host              = "192.168.1.100:8006"
proxmox_api_token_id      = "root@pam!terraform"
proxmox_api_token_secret  = "your-secret-token"
proxmox_node              = "pve"
template_name             = "ubuntu-2204-cloudinit"
```

### 3. Configure Application Settings

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
timezone: "America/New_York"
openclaw_port: 8080
openclaw_env_vars:
  NODE_ENV: "production"
  # Add your app-specific variables
```

### 4. Deploy

Full automated deployment:

```bash
./scripts/deploy.sh --full
```

Or step by step:

```bash
# Step 1: Create VM
./scripts/deploy.sh --terraform-only

# Step 2: Configure and deploy
./scripts/deploy.sh --ansible-only
```

## Deployment Options

### Option 1: Full Automation

Creates VM and configures everything:

```bash
./scripts/deploy.sh --full
```

### Option 2: Manual VM Creation

If you prefer to create the VM manually:

1. Create Ubuntu 22.04 VM in Proxmox
2. Note the IP address
3. Update `ansible/inventory/hosts`:
   ```ini
   [openclaw]
   192.168.1.150 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```
4. Run Ansible:
   ```bash
   ./scripts/deploy.sh --ansible-only
   ```

### Option 3: Configuration Only (Existing VM)

If you already have Ubuntu installed:

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

## Customization

### Custom Docker Image

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
openclaw_docker_image: "your-registry/openclaw:v1.0"
```

### Additional Services

Edit `ansible/roles/openclaw/templates/docker-compose.yml.j2` to add services like:

- PostgreSQL
- Redis
- Nginx reverse proxy

Example:

```yaml
services:
  openclaw:
    # existing config...
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: openclaw
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: openclaw
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
```

### Firewall Rules

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
ufw_allow_ports:
  - "22" # SSH
  - "80" # HTTP
  - "443" # HTTPS
  - "8080" # OpenClaw
  - "5432" # PostgreSQL (if external access needed)
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
docker ps

# View logs
docker logs openclaw-openclaw-gateway-1

# Check service health
curl http://<vm-ip>:18789/health
```

### Ansible Verification

```bash
cd ansible

# Test connectivity
ansible openclaw -m ping

# Check Docker version
ansible openclaw -a "docker --version"

# View running containers
ansible openclaw -a "docker ps"
```

## Maintenance

### Update Application

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml --tags openclaw
```

### Restart Services

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker-compose restart
```

### View Logs

```bash
ssh ubuntu@<vm-ip>

# Application logs
docker logs -f openclaw

# System logs
tail -f /opt/openclaw/logs/app.log
```

### Backup

```bash
# Backup data directory
ssh ubuntu@<vm-ip>
sudo tar -czf openclaw-backup-$(date +%Y%m%d).tar.gz /var/lib/openclaw

# Or use Proxmox backup
ssh root@proxmox-host
vzdump <vmid> --mode snapshot --storage local
```

## Destroying Infrastructure

To remove everything:

```bash
./scripts/deploy.sh --destroy
```

This will destroy the Terraform-created VM. Manual cleanup may be needed for:

- DNS records
- Firewall rules
- Backups

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
- Ensure network connectivity

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

**Docker installation fails**:

```bash
# Run specific role
ansible-playbook -i ansible/inventory/hosts playbooks/site.yml --tags docker
```

### Application Issues

**Service won't start**:

```bash
# Check Docker logs
docker logs openclaw

# Check environment variables
docker exec openclaw env

# Restart service
docker-compose restart
```

**Port conflict**:

- Change `openclaw_port` in `ansible/inventory/group_vars/all.yml`
- Re-run Ansible playbook

**Database connection fails**:

- Verify database container is running: `docker ps`
- Check database logs: `docker logs <db-container>`
- Verify connection string in environment variables

## Advanced Topics

### Using Ansible Vault for Secrets

```bash
# Create encrypted variables file
ansible-vault create ansible/inventory/group_vars/vault.yml

# Add secrets:
# vault_db_password: secret123
# vault_api_key: abc123

# Reference in all.yml:
# db_password: "{{ vault_db_password }}"

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

### CI/CD Integration

Example GitLab CI:

```yaml
deploy:
  stage: deploy
  script:
    - cd terraform && terraform init && terraform apply -auto-approve
    - cd ../ansible
    - ansible-playbook -i inventory/hosts playbooks/site.yml
  only:
    - main
```

## Support

For issues or questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs as described in [Maintenance](#maintenance)
3. Open an issue with:
   - Error messages
   - Relevant logs
   - Steps to reproduce

## Next Steps

- [ ] Configure monitoring (Prometheus, Grafana)
- [ ] Set up automated backups
- [ ] Configure SSL/TLS certificates
- [ ] Set up log aggregation
- [ ] Configure alerting
