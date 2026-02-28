# Quick Start Guide

Get OpenClaw running on Proxmox in 5 minutes!

## Prerequisites Check

- [ ] Proxmox VE accessible
- [ ] Ubuntu cloud-init template created (see [PROXMOX_SETUP.md](PROXMOX_SETUP.md))
- [ ] Proxmox API token generated
- [ ] Local SSH key exists (~/.ssh/id_rsa)

## Installation

### Step 1: Setup (2 minutes)

```bash
cd openclaw
./scripts/setup.sh
```

This will:

- Install Terraform and Ansible if needed
- Create configuration files from templates
- Install required Ansible collections

### Step 2: Configure (2 minutes)

Edit `terraform/terraform.tfvars`:

```hcl
proxmox_host              = "192.168.1.100:8006"
proxmox_api_token_id      = "root@pam!terraform"
proxmox_api_token_secret  = "your-token-here"
proxmox_node              = "pve"
```

Optionally customize `ansible/inventory/group_vars/all.yml`:

```yaml
timezone: "America/New_York"
openclaw_port: 8080
```

### Step 3: Deploy (1-5 minutes)

```bash
./scripts/deploy.sh --full
```

That's it! OpenClaw is now running.

## Access Your Application

After deployment completes, you'll see:

```
OpenClaw is now running at: http://192.168.1.150:8080
```

Open that URL in your browser!

## What Was Created?

- ✅ Ubuntu 22.04 VM on Proxmox
- ✅ Docker and Docker Compose installed
- ✅ Firewall configured
- ✅ OpenClaw running in containers
- ✅ Automatic security updates enabled

## Common Commands

```bash
# View status
./scripts/manage.sh status

# View logs
./scripts/manage.sh logs

# Restart services
./scripts/manage.sh restart

# SSH into VM
./scripts/manage.sh ssh

# Create backup
./scripts/manage.sh backup

# Update application
./scripts/manage.sh update

# Destroy everything
./scripts/deploy.sh --destroy
```

## If You Already Have a VM

Skip Terraform and just configure:

```bash
# Edit inventory with your VM IP
cp ansible/inventory/hosts.example ansible/inventory/hosts
# Edit: ansible/inventory/hosts

# Deploy
./scripts/deploy.sh --ansible-only
```

## Troubleshooting

### "Cannot connect to Proxmox"

```bash
# Test API access
curl -k "https://your-proxmox-ip:8006/api2/json/nodes" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=your-secret"
```

### "VM created but can't connect via SSH"

```bash
# Wait a bit more - cloud-init takes time
sleep 30

# Check VM in Proxmox console
# Verify IP address in inventory matches actual IP
```

### "Ansible connection fails"

```bash
# Test SSH directly
ssh ubuntu@<vm-ip>

# Check inventory file
cat ansible/inventory/hosts
```

## Using Makefile

Alternatively, use make commands:

```bash
make setup        # Run setup
make deploy-full  # Full deployment
make destroy      # Destroy infrastructure
```

See all commands:

```bash
make help
```

## Next Steps

Once running:

1. **Configure SSL/TLS**: Set up Let's Encrypt for HTTPS
2. **Setup Monitoring**: Add Prometheus/Grafana
3. **Configure Backups**: Schedule automated backups
4. **Review Firewall**: Adjust ports as needed

See [DEPLOYMENT.md](DEPLOYMENT.md) for advanced topics.

## Alternative: Ansible-only Provisioning

Don't want to use Terraform? Use Ansible to provision and configure the VM in one step:

1. Configure Proxmox connection vars in `ansible/inventory/group_vars/all.yml` (see the Proxmox provisioning section in `all.yml.example`)
2. Run:

```bash
./scripts/deploy.sh --ansible-provision
# or: make provision-ansible
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for a full comparison of both approaches.

## Need Help?

- 📖 [Full Documentation](DEPLOYMENT.md)
- 🔧 [Proxmox Setup Guide](PROXMOX_SETUP.md)
- 📋 [Requirements](REQUIREMENTS.md)
- 🤝 [Contributing](CONTRIBUTING.md)

## Architecture

```
┌─────────────────┐
│  Local Machine  │
│   (You)         │
└────────┬────────┘
         │ Terraform creates VM
         │ Ansible configures VM
         ▼
┌─────────────────┐
│  Proxmox Host   │
│                 │
│  ┌───────────┐  │
│  │ Ubuntu VM │  │
│  │           │  │
│  │ ┌───────┐ │  │
│  │ │Docker │ │  │
│  │ │       │ │  │
│  │ │OpenClaw│ │
│  │ └───────┘ │  │
│  └───────────┘  │
└─────────────────┘
```

## Deployment Time

- **VM Creation**: 1-2 minutes
- **System Configuration**: 2-3 minutes
- **Application Deployment**: 1-2 minutes
- **Total**: ~5-7 minutes

## Minimal Example

Absolutely minimal deployment:

```bash
# 1. Setup
./scripts/setup.sh

# 2. Edit terraform/terraform.tfvars (add your Proxmox details)

# 3. Deploy
./scripts/deploy.sh --full

# Done!
```

## Resource Requirements

- **Local**: 1GB disk space for tools
- **Proxmox**: 8GB RAM + 50GB disk (configurable)
- **Network**: SSH (22), HTTP (8080)

## Success Criteria

You'll know it worked when:

- ✅ Script shows "Deployment Complete!"
- ✅ You can access http://vm-ip:8080
- ✅ `./scripts/manage.sh status` shows running containers

## Support

Having issues? Check logs:

```bash
# Terraform logs
cd terraform && terraform show

# Ansible logs (verbose)
cd ansible && ansible-playbook -vvv -i inventory/hosts playbooks/site.yml

# Application logs
./scripts/manage.sh logs
```

---

**Ready to deploy?** Start with `./scripts/setup.sh`! 🚀
