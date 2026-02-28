# OpenClaw Deployment - Requirements

## System Requirements

### Local Machine (Control Node)

- OS: macOS, Linux, or Windows with WSL2
- RAM: 4GB minimum
- Disk: 1GB for tools and cache

### Proxmox Host

- Proxmox VE 7.0 or higher
- RAM: Enough for VM allocation (8GB+ recommended)
- Disk: 50GB+ available storage
- Network: Reachable from local machine

### VM Requirements (OpenClaw)

- vCPUs: 4 cores (configurable)
- RAM: 8GB (configurable)
- Disk: 50GB (configurable)
- OS: Ubuntu 22.04 LTS

## Software Requirements

### Required on Local Machine

1. **Terraform** >= 1.0
   - Installation: https://www.terraform.io/downloads
   - macOS: `brew install terraform`
   - Linux: See docs/PROXMOX_SETUP.md

2. **Ansible** >= 2.9
   - Installation: https://docs.ansible.com/ansible/latest/installation_guide/
   - macOS: `brew install ansible`
   - Linux: `sudo apt-add-repository ppa:ansible/ansible && sudo apt install ansible`

3. **Python** >= 3.8
   - macOS: Pre-installed or `brew install python3`
   - Linux: `sudo apt install python3 python3-pip`

4. **SSH Client**
   - Usually pre-installed on macOS/Linux
   - Generate key: `ssh-keygen -t rsa -b 4096`

### Required on Proxmox

1. **API Token** with appropriate permissions
   - See docs/PROXMOX_SETUP.md for creation steps

2. **Ubuntu Cloud-Init Template** (recommended)
   - OR Ubuntu ISO for manual VM creation
   - See docs/PROXMOX_SETUP.md for template creation

3. **Network Configuration**
   - Network bridge (vmbr0 or custom)
   - DHCP server OR static IP allocation

### Ansible Collections

The setup script will install these automatically:

```bash
ansible-galaxy collection install community.docker
```

Or manually:

```bash
# Required collections
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
```

## Network Requirements

### Ports Required on Proxmox

- 8006: Proxmox web interface and API (from local machine)
- 22: SSH (if managing Proxmox via SSH)

### Ports Required on VM

- 22: SSH (from local machine)
- 80: HTTP (optional, if using web interface)
- 443: HTTPS (optional, if using web interface)
- 8080: OpenClaw application (configurable)

### Firewall Considerations

- Local machine must reach Proxmox on port 8006
- Local machine must reach VM on port 22 (SSH)
- Client browsers must reach VM on application port (8080)

## Credentials Required

### Proxmox

- API Token ID (e.g., `root@pam!terraform`)
- API Token Secret

### VM Access

- SSH public key (typically `~/.ssh/id_rsa.pub`)
- Optional: VM user password

### Application (if needed)

- Database credentials
- API keys
- SSL certificates

## Optional Requirements

### For Production Deployments

- Domain name
- SSL/TLS certificates
- Database backup storage
- Monitoring solution
- Log aggregation

### For CI/CD

- GitLab/GitHub/Jenkins
- Docker registry (if using custom images)
- Secret management (Vault, etc.)

## Validation Checklist

Before running deployment, verify:

- [ ] Proxmox is accessible via API
- [ ] SSH key is generated
- [ ] Cloud-init template exists in Proxmox
- [ ] Network bridge is configured
- [ ] Storage pool has sufficient space
- [ ] terraform.tfvars is configured
- [ ] ansible/inventory/group_vars/all.yml is configured

## Quick Validation

Run these commands to validate your environment:

```bash
# Check Terraform
terraform version

# Check Ansible
ansible --version

# Check Python
python3 --version

# Check SSH key
ls -la ~/.ssh/id_rsa.pub

# Check Proxmox API (replace with your details)
curl -k "https://your-proxmox:8006/api2/json/nodes" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=your-secret"
```

## Troubleshooting

### "Terraform not found"

- Install Terraform: https://www.terraform.io/downloads
- Or run: `./scripts/setup.sh` (will attempt installation)

### "Ansible not found"

- Install Ansible: `pip3 install ansible`
- Or run: `./scripts/setup.sh` (will attempt installation)

### "Cannot connect to Proxmox"

- Verify Proxmox host is correct
- Check firewall allows port 8006
- Verify API token is valid
- Use `proxmox_tls_insecure = true` for self-signed certs

### "Cloud-init template not found"

- Create template: See docs/PROXMOX_SETUP.md
- Or use manual VM creation method

## Support

For detailed setup instructions, see:

- [PROXMOX_SETUP.md](docs/PROXMOX_SETUP.md) - Proxmox configuration
- [DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide
- [README.md](README.md) - Quick start guide
