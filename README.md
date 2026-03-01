# Proxiclaw 🦞

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/terraform-1.0%2B-blue)](https://www.terraform.io/)
[![Ansible](https://img.shields.io/badge/ansible-2.9%2B-red)](https://www.ansible.com/)

> Automated OpenClaw deployment on Proxmox using Terraform + Ansible. TLS, authentication, and git integration included.

Infrastructure as Code (IaC) for deploying [OpenClaw](https://openclaw.ai) on Proxmox VE. From zero to AI coding assistant in minutes.

## What is Proxiclaw?

**Proxiclaw** automates the complete setup of OpenClaw (an AI-powered coding assistant) on your Proxmox infrastructure using a two-phase deployment approach:

**Phase 1: Terraform** → Creates and provisions Ubuntu VMs on Proxmox
**Phase 2: Ansible** → Installs and configures OpenClaw with all dependencies

The result: A fully functional, secure AI coding assistant with HTTPS, authentication, git integration, and automated backups - all configured automatically.

## Architecture Overview

### Why Two Tools?

This project uses Terraform and Ansible for different purposes, following infrastructure best practices:

**🏗️ Terraform: Infrastructure Provisioning**

- **What it does:** Creates virtual machines on Proxmox
- **Handles:** VM resources (CPU, memory, disk), networking, cloud-init configuration
- **Output:** A running Ubuntu 22.04 VM ready for software installation
- **Runs:** Once to provision the VM (or to modify/destroy infrastructure)

**⚙️ Ansible: Configuration Management**

- **What it does:** Configures the VM and installs OpenClaw
- **Handles:** Docker installation, OpenClaw deployment, TLS setup, API keys, backups
- **Output:** Fully configured OpenClaw instance with all integrations working
- **Runs:** Once for initial setup, or repeatedly to update configuration (idempotent)

**The Flow:**

```
Terraform → Creates VM on Proxmox → Gets IP address
    ↓
Ansible → Connects to VM → Installs everything → OpenClaw ready!
```

### What You Get

- 🔐 **Security**: HTTPS with auto-generated TLS certificates and token-based authentication
- 🔑 **Git Integration**: Automatic SSH key mounting for private repository access
- 🤖 **AI Models**: Claude 3.5 Sonnet configured by default (cost-optimized)
- 💾 **Backups**: Automated configuration backups to git repositories
- 📦 **Complete Setup**: API keys, models, and workspace ready out of the box

---

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Detailed Setup Guide](#detailed-setup-guide) - First-time Proxmox configuration
- [Configuration](#configuration) - Terraform and Ansible variables
- [Accessing OpenClaw](#accessing-openclaw) - Authentication and device pairing
- [Troubleshooting](#troubleshooting)
- [Documentation](#documentation) - Additional guides

---

## Features

✨ **Fully Automated Deployment**

- Single command deployment: Terraform → VM → Ansible → OpenClaw running
- Zero manual Docker or configuration required
- Idempotent playbooks (safe to re-run and update)

🔒 **Production-Ready Security**

- HTTPS with auto-generated TLS certificates (or bring your own)
- Token-based authentication with device pairing
- SSH key mounting for secure git operations
- API keys automatically configured (never stored in git)

🛠️ **Developer Optimized**

- Private GitHub/GitLab repo access via SSH
- Git config automatically mounted
- Claude 3.5 Sonnet configured by default (best coding performance)
- Workspace persistence across restarts
- Automated configuration backups to git

📚 **Comprehensive Documentation**

- Step-by-step setup guides for every component
- Common commands reference
- Troubleshooting guides
- Multiple SSL/TLS configuration options

## Quick Start

**Prerequisites:** Terraform, Ansible, and a Proxmox server with API access. First time? See [Detailed Setup Guide](#detailed-setup-guide) below.

```bash
# 1. Clone and navigate to the project
git clone https://github.com/btotharye/proxiclaw.git
cd proxiclaw

# 2. Configure Terraform (tells it HOW to create the VM)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
vim terraform/terraform.tfvars  # Edit: Proxmox host, API token, VM specs, storage

# 3. Configure Ansible (tells it WHAT to install on the VM)
cp ansible/inventory/group_vars/all.yml.example ansible/inventory/group_vars/all.yml
vim ansible/inventory/group_vars/all.yml  # Edit: API keys, models, SSL options

# 4. PHASE 1: Create VM with Terraform
cd terraform
terraform init
terraform apply  # Creates Ubuntu VM on Proxmox

# 5. Get the new VM's IP address
terraform output vm_ip_address

# 6. Update Ansible inventory with the VM IP
cd ../ansible
vim inventory/hosts  # Add the IP from step 5

# 7. PHASE 2: Install OpenClaw with Ansible
ansible-playbook -i inventory/hosts playbooks/site.yml  # Installs Docker, OpenClaw, etc.

# 8. Access OpenClaw in your browser
# https://<vm-ip>:18789
```

See [docs/QUICK_START.md](docs/QUICK_START.md) for detailed walkthrough with screenshots.

---

## Detailed Setup Guide

### Prerequisites

Before running Proxiclaw, ensure you have:

**On Your Local Machine:**

- Terraform >= 1.0
- Ansible >= 2.9 (`brew install ansible` on macOS or `pip3 install ansible`)
- Python 3.12+
- SSH key pair (`~/.ssh/id_rsa.pub`)
- ssh-agent with your key loaded: `ssh-add ~/.ssh/id_rsa`

**On Your Proxmox Server:**

- Proxmox VE 7.0+
- API token with necessary permissions
- Ubuntu 22.04 cloud-init template (see below)
- SSH access to Proxmox host
- Local datastore configured to support 'snippets' content type
- Storage for VM disks (e.g., local-zfs, local-lvm)
- Network bridge configured (e.g., vmbr0)

### First-Time Proxmox Setup

Complete these steps once before your first deployment:

#### Step 1: Enable SSH Key Authentication

Before running Terraform, you need to set up SSH key authentication to your Proxmox host (required for cloud-init file uploads):

```bash
# Add your SSH key to the Proxmox host
ssh-copy-id root@your-proxmox-host

# Verify key authentication works
ssh root@your-proxmox-host "echo 'SSH key auth working'"

# Ensure your key is loaded in ssh-agent
ssh-add -L  # Should list your keys
# If empty, add your key:
ssh-add ~/.ssh/id_rsa
```

### Step 2: Enable Snippets on Local Storage

The Terraform configuration uses cloud-init snippets which must be enabled on a directory-based datastore:

```bash
# SSH to your Proxmox host
ssh root@your-proxmox-host

# Check current datastores
pvesm status

# Enable snippets on the 'local' datastore
pvesm set local --content backup,iso,vztmpl,snippets

# Verify snippets are enabled
pvesm status -content snippets
```

### Step 3: Discover Your Storage and Network Configuration

Before configuring Terraform, identify your storage and network setup:

```bash
# SSH to your Proxmox host
ssh root@your-proxmox-host

# Check available storage for VM disks
pvesm status
# Note the storage names (e.g., local-zfs, local-lvm, local)

# Check network bridges
ip link show | grep vmbr
# Note your bridge names (e.g., vmbr0, vmbr30)
```

Update your `terraform/terraform.tfvars` with the correct storage and bridge names from above.

## Proxmox API Token Setup

Before deploying, you need to create an API token in Proxmox:

### Create API Token

1. Log into your Proxmox web interface (https://your-proxmox-ip:8006)
2. Navigate to **Datacenter → Permissions → API Tokens**
3. Click the **Add** button
4. Fill in the token details:
   - **User**: `root@pam`
   - **Token ID**: `terraform` (or your preferred name)
   - **Privilege Separation**: **Unchecked** (uncheck this for full access)
5. Click **Add**
6. **Important**: Copy and save the token secret immediately - it won't be shown again!

Your API token ID will be in the format: `root@pam!terraform`

### Verify API Access

Test your API token from your local machine:

```bash
curl -k "https://your-proxmox-ip:8006/api2/json/nodes" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=your-secret-token-here"
```

You should receive a JSON response with your Proxmox node information.

### Create Cloud-Init Template

For automated VM creation, create an Ubuntu cloud-init template:

```bash
# SSH to your Proxmox host
ssh root@your-proxmox-host

# Download Ubuntu 22.04 cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Check available storage and note the storage name and network bridge
pvesm status
ip link show | grep vmbr

# Create a VM template (ID 9000)
# IMPORTANT: Replace 'local-lvm' with YOUR storage name from pvesm status output
# IMPORTANT: Replace 'vmbr0' with YOUR bridge name from ip link show output
# Common storage names: local, local-lvm, local-zfs
# Common bridge names: vmbr0, vmbr30

# Example using local-lvm and vmbr0:
qm create 9000 --name ubuntu-2204-cloudinit --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Example using local-zfs and vmbr30:
# qm create 9000 --name ubuntu-2204-cloudinit --memory 2048 --net0 virtio,bridge=vmbr30
# qm importdisk 9000 jammy-server-cloudimg-amd64.img local-zfs
# qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9000-disk-0
# qm set 9000 --ide2 local-zfs:cloudinit
# qm set 9000 --boot c --bootdisk scsi0
# qm set 9000 --serial0 socket --vga serial0
# qm set 9000 --agent enabled=1

# Convert to template
qm template 9000

# Clean up
rm jammy-server-cloudimg-amd64.img
```

**Important Notes:**

- The template creation must use the same storage that you'll configure in `terraform.tfvars` as `vm_storage`
- The network bridge must match what you'll configure as `vm_network_bridge`
- The qemu-guest-agent will be installed automatically by the Terraform cloud-init configuration

See [docs/PROXMOX_SETUP.md](docs/PROXMOX_SETUP.md) for detailed instructions and troubleshooting.

---

## Configuration

This section covers all configuration files you'll need to edit before deployment.

### Terraform Variables (`terraform/terraform.tfvars`)

Configure Proxmox connection and VM specifications:

```hcl
# Proxmox Connection
proxmox_host = "192.168.30.11:8006"  # Your Proxmox host:port
proxmox_node = "proxmox-1"            # Your Proxmox node name
proxmox_api_token_id = "root@pam!terraform"
proxmox_api_token_secret = "your-secret-token-here"

# VM Configuration
vm_name = "openclaw-vm"
vm_cores = 4
vm_memory = 8192
vm_disk_size = "100G"

# Storage and Network (CRITICAL: Must match your Proxmox setup)
vm_storage = "local-zfs"        # From 'pvesm status'
vm_network_bridge = "vmbr30"    # From 'ip link show'
template_name = "9000"          # Your cloud-init template VM ID

# SSH Configuration
ssh_public_key_file = "~/.ssh/id_rsa.pub"
vm_user = "ubuntu"
```

**Important Notes:**

- This project uses the `bpg/proxmox` Terraform provider (actively maintained)
- Storage and network bridge names vary by Proxmox installation - verify yours first
- The cloud-init configuration automatically installs qemu-guest-agent

### Ansible Variables (`ansible/inventory/group_vars/all.yml`)

#### AI Provider Setup

OpenClaw supports multiple AI providers with different authentication methods:

**Option 1: GitHub Copilot+ Subscription (Recommended for heavy usage)**

Use your GitHub Copilot+ subscription instead of paying per token:

```yaml
# GitHub Copilot+ subscription
primary_ai_provider: "copilot"
```

After deployment, run interactive OAuth setup to connect your subscription.

**Option 2: API Keys (Pay-per-use)**

```yaml
# Use API credits (pay per token)
primary_ai_provider: "api_keys_only"
anthropic_api_key: "sk-ant-your-key-here" # Claude requires API key
openai_api_key: "sk-proj-your-key-here"
openclaw_default_model: "anthropic/claude-sonnet-4-6"
```

**Option 3: Mixed (Copilot + API Keys)**

Use Copilot subscription for primary work and API keys as fallback:

```yaml
primary_ai_provider: "copilot"
# Add API keys for other providers as needed
anthropic_api_key: "sk-ant-your-key-here" # Claude fallback
openai_api_key: "sk-proj-your-key-here" # OpenAI fallback
```

📖 **Complete setup guide:** [docs/AI_PROVIDER_SETUP.md](docs/AI_PROVIDER_SETUP.md)

**The Ansible playbook automatically configures API keys. For GitHub Copilot+, you'll complete an interactive OAuth flow after deployment.**

> **💡 Note:** Claude Sonnet 4.6 is available through GitHub Copilot+ subscription at no extra cost!

**Recommended Models for Coding (Cost vs Performance):**

| Model                         | Cost                      | Use Case                                                |
| ----------------------------- | ------------------------- | ------------------------------------------------------- |
| `anthropic/claude-sonnet-4-6` | $3-4/$12-15 per 1M tokens | **Best value** - Complex coding, refactoring, debugging |
| `anthropic/claude-haiku-3`    | $0.80/$4 per 1M tokens    | Simple tasks, code reviews (75% cheaper)                |
| `gpt-4o-mini`                 | $0.15/$0.60 per 1M tokens | Basic scripts, simple questions (90% cheaper)           |

### Web Service API Keys (Optional)

Enable web search, scraping, and other online tools:

```yaml
# Add to ansible/inventory/group_vars/all.yml
braveapi_key: "BSAxxx..." # Brave Search API
serper_api_key: "xxx..." # Serper.dev Google Search API
firecrawl_api_key: "fc-xxx..." # Firecrawl web scraping
```

**Or configure interactively on the VM:**

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section web
```

These keys are also auto-configured in `auth-profiles.json` when set in Ansible.

### SSL/HTTPS Setup (Optional but Recommended)

For secure HTTPS access on your local network:

```yaml
# Enable TLS with auto-generated self-signed certificate
openclaw_enable_tls: true

# OR provide your own certificate (e.g., from mkcert)
openclaw_enable_tls: true
openclaw_tls_cert_path: "/home/ubuntu/.openclaw/certs/cert.pem"
openclaw_tls_key_path: "/home/ubuntu/.openclaw/certs/key.pem"
```

**SSL Options:**

- **Self-signed (auto):** Set `openclaw_enable_tls: true` (browser warnings expected)
- **mkcert (recommended):** Locally-trusted certificates, no warnings - see [SSL Setup Guide](docs/SSL_SETUP.md)
- **Tailscale:** Secure mesh network with built-in HTTPS
- **Let's Encrypt:** Production-ready if you have a domain

📖 **Full SSL setup guide:** [docs/SSL_SETUP.md](docs/SSL_SETUP.md)

### Backup Configuration (Optional but Recommended)

Automatically back up your OpenClaw configuration and workspace metadata to a git repository.

**What gets backed up:**

- ✅ `openclaw.json` - Main configuration
- ✅ `devices/paired.json` - Device pairing (no secrets)
- ✅ `.cursorrules` files - Your AI guardrails for each project
- ❌ API keys (never committed)
- ❌ Workspace code (use per-project git repos)

**Setup:**

1. Create a private GitHub repo (e.g., `openclaw-config-backup`)

2. Configure in `ansible/inventory/group_vars/all.yml`:

```yaml
openclaw_backup_repo: "git@github.com:yourusername/openclaw-config-backup.git"

# Optional: customize schedule (default: daily at 2 AM)
openclaw_backup_cron_hour: "2"
```

3. Deploy with Ansible (backup will run automatically)

**Manual backup:**

```bash
ssh ubuntu@<vm-ip>
~/openclaw-backups/backup.sh
```

**Initialize workspace projects as git repos:**

```bash
ssh ubuntu@<vm-ip>
~/bin/init-workspace-repos.sh
```

This script will:

- Create git repos for each workspace project
- Add `.gitignore` and `README.md` templates
- Include your `.cursorrules` files
- Make initial commits

Then push each project to its own GitHub repo!

📖 **Full backup documentation:** [ansible/roles/openclaw-backup/README.md](ansible/roles/openclaw-backup/README.md)

## Accessing OpenClaw

After deployment, OpenClaw will be accessible at:

- **HTTP:** `http://<vm-ip>:18789` (requires SSL for some features)
- **HTTPS:** `https://<vm-ip>:18789` (recommended)

### First-Time Authentication

1. **Get the Gateway Token:**

   ```bash
   ssh ubuntu@<vm-ip> "grep -oP '\"token\":\s*\"\K[^\"]+' ~/.openclaw/openclaw.json"
   ```

2. **Access with Token:**
   Open in your browser: `https://<vm-ip>:18789/#token=YOUR_TOKEN_HERE`

3. **Approve Device Pairing:**

   ```bash
   # List pending device pairing requests
   ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices list"

   # Approve the pairing request (use the Request ID from above)
   ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices approve <REQUEST_ID>"
   ```

4. **Refresh Browser** - Your device is now paired and authenticated!

### Managing Devices

```bash
# List all devices (pending and paired)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices list"

# Remove a paired device
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices remove <DEVICE_ID>"

# Clear all paired devices
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices clear"
```

For more commands, see [docs/COMMON_COMMANDS.md](docs/COMMON_COMMANDS.md)

### Using OpenClaw

Once authenticated, you're ready to start using OpenClaw as your AI coding assistant!

📖 **Complete usage guide:** [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)

**Quick examples:**

```
You: Clone https://github.com/username/myproject.git and list the files

You: Create a Python script that processes JSON files in the data/ directory

You: Add error handling to the main function in app.py

You: Run the tests and show me any failures

You: Create a new branch called 'feature/new-api' and add a REST endpoint
```

**Setting up Git access:**

**Note:** The Ansible deployment automatically mounts your `~/.ssh` directory and `.gitconfig` from the VM into the OpenClaw container. Once you configure SSH keys on the VM, OpenClaw will immediately have access to them.

```bash
# SSH into the VM and configure git
ssh ubuntu@<vm-ip>
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Set up SSH keys for GitHub/GitLab (recommended)
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub  # Add this to your Git provider

# Configure SSH for GitHub
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519

# Test SSH connection
ssh -T git@github.com

# Restart OpenClaw to mount the SSH keys
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"
```

---

## Directory Structure

```
.
├── terraform/           # Proxmox VM provisioning
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/            # Configuration management
│   ├── inventory/
│   │   ├── hosts.example
│   │   └── group_vars/
│   ├── playbooks/
│   │   ├── site.yml
│   │   ├── provision-vm.yml
│   │   ├── configure-system.yml
│   │   └── deploy-openclaw.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── docker/
│   │   └── openclaw/
│   └── ansible.cfg
└── scripts/            # Helper scripts
    ├── setup.sh
    └── deploy.sh
```

---

## Manual Steps (Alternative to Terraform)

If you prefer to create the VM manually instead of using Terraform:

1. Create Ubuntu 22.04 VM in Proxmox
2. Note the IP address
3. Ensure SSH access with your key
4. Update `ansible/inventory/hosts` with the IP
5. Run Ansible playbook

## Troubleshooting

### Terraform Issues

**Error: "failed to open SSH client: unable to authenticate"**

- Ensure you've set up SSH key authentication to Proxmox host: `ssh-copy-id root@your-proxmox-host`
- Verify your SSH key is loaded: `ssh-add -L`
- If empty, add your key: `ssh-add ~/.ssh/id_rsa`

**Error: "datastore does not support content type 'snippets'"**

- Enable snippets on local storage: `ssh root@proxmox-host "pvesm set local --content backup,iso,vztmpl,snippets"`
- Verify: `ssh root@proxmox-host "pvesm status -content snippets"`

**Error: "storage 'local-lvm' does not exist" or similar**

- Check your actual storage names: `ssh root@proxmox-host "pvesm status"`
- Update `vm_storage` in `terraform.tfvars` with the correct storage name (e.g., local-zfs)

**Error: "bridge 'vmbr0' does not exist" or similar**

- Check your network bridges: `ssh root@proxmox-host "ip link show | grep vmbr"`
- Update `vm_network_bridge` in `terraform.tfvars` with your bridge name

**Error: "timeout while waiting for the QEMU agent"**

- The guest agent is being installed via cloud-init and takes ~30-60 seconds after VM creation
- Check cloud-init status: `ssh root@proxmox-host "qm guest exec VM_ID -- cloud-init status"`
- Verify agent is running: `ssh root@proxmox-host "qm agent VM_ID ping"`

**SSH authentication fails to newly created VM**

- The Terraform configuration uses cloud-init to install your SSH key
- Verify the key in terraform.tfvars matches your actual key: `cat ~/.ssh/id_rsa.pub`
- Check cloud-init completed: `ssh root@proxmox-host "qm guest exec VM_ID -- tail /var/log/cloud-init-output.log"`

### Ansible Issues

- Verify SSH access: `ssh ubuntu@<vm-ip>`
- Check Python is installed on target: `ansible all -m ping -i inventory/hosts`
- Run with verbose: `ansible-playbook -vvv -i inventory/hosts playbooks/site.yml`
- Ensure Ansible is installed: `brew install ansible` (macOS) or `pip3 install ansible`

### Git / SSH Key Issues

**OpenClaw says "No git credentials configured"**

The Ansible playbook automatically mounts your VM's `~/.ssh` directory into the OpenClaw container. If git authentication isn't working:

1. **Verify SSH keys are configured on the VM:**

   ```bash
   ssh ubuntu@<vm-ip>
   ls -la ~/.ssh/id_ed25519*  # Should exist
   cat ~/.ssh/config  # Should have GitHub/GitLab config
   ssh -T git@github.com  # Test authentication
   ```

2. **Restart OpenClaw to mount SSH keys:**

   ```bash
   ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"
   ```

3. **Verify SSH keys are visible inside container:**

   ```bash
   ssh ubuntu@<vm-ip> "docker exec openclaw-openclaw-gateway-1 ls -la /home/node/.ssh/"
   ssh ubuntu@<vm-ip> "docker exec openclaw-openclaw-gateway-1 ssh -T git@github.com"
   ```

4. **Check docker-compose override exists:**
   ```bash
   ssh ubuntu@<vm-ip> "cat /opt/openclaw/docker-compose.override.yml"
   # Should show SSH and .gitconfig volume mounts
   ```

If SSH keys still aren't working, the Ansible playbook creates `docker-compose.override.yml` that mounts:

- `/home/ubuntu/.ssh:/home/node/.ssh:ro` (SSH keys)
- `/home/ubuntu/.gitconfig:/home/node/.gitconfig:ro` (Git config)

### Getting VM IP Address

If Terraform doesn't show the IP address (guest agent not ready), get it manually:

```bash
# Via guest agent (preferred):
ssh root@proxmox-host "qm agent VM_ID network-get-interfaces" | grep '"ip-address"' | grep 192.168

# Via Proxmox CLI:
ssh root@proxmox-host "qm list"
# Then check DHCP leases or Proxmox web UI
```

## Security Notes

- Never commit `terraform.tfvars` or files with secrets
- Use Ansible Vault for sensitive variables
- Restrict API token permissions to minimum required
- Use SSH keys, not passwords
- The Terraform configuration uses SSH key authentication for VM access
- SSH keys are automatically installed via cloud-init during VM creation

## How It Works

### Cloud-Init Integration

The Terraform configuration creates a custom cloud-init user data file that:

1. Creates the ubuntu user with sudo access
2. Installs your SSH public key for authentication
3. Installs and enables qemu-guest-agent for VM management
4. Configures the system for first boot

This approach ensures VMs are fully configured and accessible immediately after creation, with no manual intervention required.

### Provider Details

This project uses the `bpg/proxmox` Terraform provider instead of the older Telmate provider because:

- Actively maintained and up-to-date
- Better support for modern Proxmox versions
- Improved cloud-init integration
- More reliable guest agent interaction

## Documentation

- **[AI Provider Setup](docs/AI_PROVIDER_SETUP.md)** - Configure GitHub Copilot+, Claude Pro/Max, or API keys
- **[Getting Started Guide](docs/GETTING_STARTED.md)** - Using OpenClaw as your AI assistant
- **[Common Commands](docs/COMMON_COMMANDS.md)** - Quick reference for frequent tasks
- **[SSL Setup Guide](docs/SSL_SETUP.md)** - Configure HTTPS with various methods
- **[Proxmox Setup](docs/PROXMOX_SETUP.md)** - Detailed Proxmox configuration

## Quick Reference

| Task              | Command                                                                                                               |
| ----------------- | --------------------------------------------------------------------------------------------------------------------- |
| Get gateway token | `ssh ubuntu@<vm-ip> "grep -oP '\"token\":\s*\"\K[^\"]+' ~/.openclaw/openclaw.json"`                                   |
| List devices      | `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices list"`                 |
| Approve device    | `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices approve <REQUEST_ID>"` |
| View logs         | `ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 -f"`                                                     |
| Restart OpenClaw  | `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart"`                                                     |
| Check health      | `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw health"`                       |

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenClaw](https://openclaw.ai) - The AI coding assistant this deploys
- [Proxmox VE](https://www.proxmox.com/) - Virtualization platform
- [bpg/proxmox](https://github.com/bpg/terraform-provider-proxmox) - Terraform provider

## Support

- 📖 Check the [documentation](docs/)
- 🐛 [Open an issue](https://github.com/btotharye/proxiclaw/issues)
- 💬 Share your experience

---

Made with 🦞 by [Brian Totharye](https://github.com/btotharye)
