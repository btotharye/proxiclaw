# OpenClaw Common Commands

Quick reference for frequently used OpenClaw commands.

## Table of Contents

- [Accessing the VM](#accessing-the-vm)
- [Container Management](#container-management)
- [Device & Authentication](#device--authentication)
- [Configuration](#configuration)
- [Logs & Debugging](#logs--debugging)
- [Gateway Management](#gateway-management)
- [Models & Agents](#models--agents)
- [Git & Repository Access](#git--repository-access)
- [Backup & Maintenance](#backup--maintenance)

## Accessing the VM

```bash
# SSH into the VM
ssh ubuntu@<vm-ip>

# Check if OpenClaw is running
ssh ubuntu@<vm-ip> "docker ps"

# Get container status
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose ps"
```

## Container Management

### Basic Operations

```bash
# Start OpenClaw
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose up -d"

# Stop OpenClaw
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose down"

# Restart OpenClaw
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart"

# Restart just the gateway
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"

# View running containers
ssh ubuntu@<vm-ip> "docker ps"

# Check container health
ssh ubuntu@<vm-ip> "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

### Updates

```bash
# Pull latest OpenClaw image
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose pull"

# Update and restart
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose pull && docker compose up -d"

# Check current version
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw --version"
```

## Device & Authentication

### Get Gateway Token

```bash
# Extract token from config
ssh ubuntu@<vm-ip> "grep -oP '\"token\":\s*\"\K[^\"]+' ~/.openclaw/openclaw.json"
```

### Device Pairing

```bash
# List all devices (pending and paired)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices list"

# Approve a pending pairing request
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices approve <REQUEST_ID>"

# Reject a pending pairing request
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices reject <REQUEST_ID>"

# Remove a paired device
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices remove <DEVICE_ID>"

# Clear all paired devices (use with caution!)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices clear"
```

### Access URLs

Once you have your token, access OpenClaw at:

```
https://<vm-ip>:18789/#token=YOUR_TOKEN_HERE
```

## Configuration

### View Current Config

```bash
# View full config
ssh ubuntu@<vm-ip> "cat ~/.openclaw/openclaw.json"

# View formatted config (if jq is installed)
ssh ubuntu@<vm-ip> "cat ~/.openclaw/openclaw.json | jq ."

# View environment variables
ssh ubuntu@<vm-ip> "cat /opt/openclaw/.env"
```

### Check API Keys

```bash
# Check which API keys are configured
ssh ubuntu@<vm-ip> "grep -E 'ANTHROPIC_API_KEY|OPENAI_API_KEY' /opt/openclaw/.env"

# Verify keys are set (without showing the full key)
ssh ubuntu@<vm-ip> "grep -E 'ANTHROPIC_API_KEY|OPENAI_API_KEY' /opt/openclaw/.env | sed 's/=.*/=***HIDDEN***/'"

# Check agent auth profiles (should be auto-configured by Ansible)
ssh ubuntu@<vm-ip> "cat ~/.openclaw/agents/main/agent/auth-profiles.json"
```

### Configure API Keys Manually

If you deployed without Ansible or need to add/update API keys:

```bash
# Interactive configuration wizard
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw configure --section model"

# Follow the prompts:
# 1. Select provider (anthropic or openai)
# 2. Paste your API key
# 3. Choose if it should be default
# 4. Add more providers if needed
# 5. Save configuration

# Note: Ansible deployments auto-configure this, so manual setup is typically not needed
```

### Update Configuration

```bash
# Edit config directly (backup first!)
ssh ubuntu@<vm-ip> "cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak"
ssh ubuntu@<vm-ip> "vi ~/.openclaw/openclaw.json"

# Restart after config changes
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"
```

## Logs & Debugging

### Container Logs

```bash
# View recent gateway logs
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 --tail 50"

# Follow logs in real-time
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 -f"

# View logs since a specific time
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 --since 10m"

# Search logs for errors
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 2>&1 | grep -i error"

# Search for authentication issues
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 2>&1 | grep -i 'auth\|pair\|device'"
```

### Gateway Log Files

```bash
# View OpenClaw log file (inside container)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway tail -f /tmp/openclaw/openclaw-*.log"

# Check gateway health
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw health"
```

### System Logs

```bash
# Check Docker service logs
ssh ubuntu@<vm-ip> "journalctl -u docker --since '10 minutes ago'"

# Check system logs for Docker
ssh ubuntu@<vm-ip> "sudo dmesg | grep -i docker"
```

## Gateway Management

### Gateway Status

```bash
# Check if gateway is running
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw status"

# Check gateway health
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw health"

# View gateway configuration
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw config"
```

### Security Audit

```bash
# Run security audit
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw security audit"

# Run doctor (health checks + quick fixes)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw doctor"

# Fix config compatibility issues
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw doctor --fix"
```

## Models & Agents

### List Available Models

```bash
# List all available models
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw models list"

# Scan for new models
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw models scan"
```

### Test Agent

```bash
# Send a test message to the agent
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw agent --message 'Hello, what can you do?'"
```

### Agent Configuration

```bash
# View agent configuration
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw config get agents.defaults"

# List agent sessions
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw sessions list"
```

## Git & Repository Access

### SSH Key Setup (One-Time)

For private repositories, set up SSH keys on the VM:

```bash
ssh ubuntu@<vm-ip>

# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Display public key
cat ~/.ssh/id_ed25519.pub
# Copy this and add to GitHub: https://github.com/settings/keys

# Configure SSH
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519

# Test
ssh -T git@github.com
# Should show: "Hi username! You've successfully authenticated"

# Configure git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Important:** After setting up SSH keys, restart OpenClaw for changes to take effect:

```bash
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"
```

**Note:** The Ansible deployment automatically mounts `~/.ssh` and `~/.gitconfig` into the container via `docker-compose.override.yml`, so OpenClaw will use your SSH keys once configured.

### Clone Repository

```bash
# In OpenClaw chat:
"Clone git@github.com:username/repo.git into the workspace"  # Private repos with SSH
"Clone https://github.com/username/repo.git into the workspace"  # Public repos
```

### Verify SSH Access Inside Container

```bash
# Check if SSH keys are mounted
ssh ubuntu@<vm-ip> "docker exec openclaw-openclaw-gateway-1 ls -la /home/node/.ssh/"

# Test GitHub SSH from inside container
ssh ubuntu@<vm-ip> "docker exec openclaw-openclaw-gateway-1 ssh -T git@github.com"
# Should show: "Hi username! You've successfully authenticated"

# Test git clone from inside container
ssh ubuntu@<vm-ip> "docker exec openclaw-openclaw-gateway-1 sh -c 'cd /home/node/.openclaw/workspace && git clone git@github.com:username/repo.git test && rm -rf test'"
```

## Backup & Maintenance

### Backup Configuration

```bash
# Backup config and workspace
ssh ubuntu@<vm-ip> "tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw/"

# Download backup to local machine
scp ubuntu@<vm-ip>:~/openclaw-backup-*.tar.gz ./

# Backup just the config
ssh ubuntu@<vm-ip> "cp ~/.openclaw/openclaw.json ~/openclaw-config-$(date +%Y%m%d).json"
```

### Restore Configuration

```bash
# Restore from backup
scp ./openclaw-backup-*.tar.gz ubuntu@<vm-ip>:~/
ssh ubuntu@<vm-ip> "cd ~ && tar -xzf openclaw-backup-*.tar.gz"
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart"
```

### Clean Up

```bash
# Remove old/unused Docker images
ssh ubuntu@<vm-ip> "docker image prune -a"

# Remove all stopped containers
ssh ubuntu@<vm-ip> "docker container prune"

# View disk usage
ssh ubuntu@<vm-ip> "df -h"
ssh ubuntu@<vm-ip> "docker system df"
```

### Update System

```bash
# Update Ubuntu packages
ssh ubuntu@<vm-ip> "sudo apt update && sudo apt upgrade -y"

# Update Docker
ssh ubuntu@<vm-ip> "sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y"
```

## Useful One-Liners

### Quick Status Check

```bash
# Full status check
ssh ubuntu@<vm-ip> "echo '=== Docker ===' && docker ps && echo -e '\n=== OpenClaw Version ===' && cd /opt/openclaw && docker compose exec openclaw-gateway openclaw --version && echo -e '\n=== Health ===' && docker compose exec openclaw-gateway openclaw health"
```

### Monitor In Real Time

```bash
# Watch container stats
ssh ubuntu@<vm-ip> "docker stats"

# Monitor logs with grep
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 -f 2>&1 | grep -E 'error|warning|unauthorized'"
```

### Connection Test

```bash
# Test HTTP/HTTPS from your local machine
curl -k https://<vm-ip>:18789

# Test with headers
curl -k -I https://<vm-ip>:18789
```

## Troubleshooting

### Container Won't Start

```bash
# Check detailed logs
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1"

# Check compose file
ssh ubuntu@<vm-ip> "cat /opt/openclaw/docker-compose.yml"

# Verify .env file
ssh ubuntu@<vm-ip> "cat /opt/openclaw/.env"

# Try starting in foreground (see errors immediately)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose up"
```

### Authentication Issues

```bash
# Reset rate limit (restart container)
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart openclaw-gateway"

# Check for rate limiting in logs
ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 2>&1 | grep -i 'rate\|limit'"

# Clear all devices and start fresh
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices clear"
```

### SSL/TLS Issues

```bash
# Check TLS configuration
ssh ubuntu@<vm-ip> "grep -A5 'tls' ~/.openclaw/openclaw.json"

# Check if certificates exist (if not using autoGenerate)
ssh ubuntu@<vm-ip> "ls -la ~/.openclaw/certs/"

# Test HTTPS locally from VM
ssh ubuntu@<vm-ip> "curl -k -I https://localhost:18789"
```

## Help Commands

```bash
# Main help
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw --help"

# Specific command help
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw devices --help"
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw models --help"
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw config --help"
```

## Tips

- **Alias for convenience:** Add to your `~/.zshrc` or `~/.bashrc`:

  ```bash
  alias openclaw-ssh='ssh ubuntu@<vm-ip>'
  alias openclaw-logs='ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 -f"'
  alias openclaw-exec='ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw"'
  ```

- **Use tmux/screen:** When running long commands on the VM, use `tmux` or `screen` to prevent disconnection issues

- **Regular backups:** Set up a cron job to automatically backup your configuration

- **Monitor logs:** Keep an eye on logs after making configuration changes to catch issues early
