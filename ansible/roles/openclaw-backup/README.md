# OpenClaw Backup Role

Automatically backs up OpenClaw configuration and workspace metadata to a git repository.

## What Gets Backed Up

### Configuration Files

- `openclaw.json` - Main OpenClaw configuration
- `devices/paired.json` - Device pairing information (no secrets)

### Workspace Metadata

- `.cursorrules` files - Your AI guardrails for each project
- Project metadata (but not the actual code - that should be in separate repos)

### What's Excluded

- API keys (`auth-profiles.json`) - NEVER committed
- SSH keys and certificates
- Log files
- Session history
- Actual workspace code (use git per-project)

## Setup

### 1. Create a Backup Repository

```bash
# On GitHub, create a private repo called "openclaw-config-backup"
# Then get the SSH URL
```

### 2. Configure in Ansible

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
openclaw_backup_repo: "git@github.com:yourusername/openclaw-config-backup.git"

# Optional: customize schedule (default: daily at 2 AM)
openclaw_backup_cron_minute: "0"
openclaw_backup_cron_hour: "2"
```

### 3. Deploy

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

## Usage

### Manual Backup

```bash
ssh ubuntu@your-proxmox-vm
~/openclaw-backups/backup.sh
```

### Initialize Git Repos for Workspace Projects

This script sets up git repositories for all your OpenClaw workspace projects:

```bash
ssh ubuntu@your-proxmox-vm
~/bin/init-workspace-repos.sh
```

This will:

- ✓ Initialize git in each workspace project
- ✓ Create .gitignore files
- ✓ Create README.md templates
- ✓ Make initial commits
- ✓ Include .cursorrules files in each repo

Then push each project to its own GitHub repo:

```bash
cd ~/.openclaw/workspace/my-project
git remote add origin git@github.com:yourusername/my-project.git
git push -u origin main
```

### Check Backup Logs

```bash
ssh ubuntu@your-proxmox-vm
tail -f ~/openclaw-backups/backup.log
```

### View Cron Job

```bash
ssh ubuntu@your-proxmox-vm
crontab -l | grep openclaw
```

## Best Practices

### Three-Tier Backup Strategy

1. **Config Backups** (this role)
   - OpenClaw settings (daily automated)
   - Device pairing info
   - Workspace .cursorrules files

2. **Workspace Projects** (per-project git)
   - Each project is its own repo
   - Code + .cursorrules together
   - Standard git workflow

3. **VM Snapshots** (Proxmox)
   - Weekly full VM snapshots
   - Disaster recovery
   - Before major upgrades

### Recommended Workflow

```bash
# After creating a new workspace project in OpenClaw:
ssh ubuntu@your-vm
cd ~/.openclaw/workspace/new-project

# Initialize git
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo and push
git remote add origin git@github.com:yourusername/new-project.git
git push -u origin main

# Clone locally on your Mac
git clone git@github.com:yourusername/new-project.git
```

Now you can:

- Edit locally or via OpenClaw
- Commit and push changes
- Your .cursorrules travel with the code
- Config is backed up separately

## Troubleshooting

### Backup script fails to push

**Problem**: SSH keys not set up for git in VM

**Solution**:

```bash
# Generate SSH key on VM
ssh ubuntu@your-vm
ssh-keygen -t ed25519 -C "openclaw@your-vm"

# Add to GitHub
cat ~/.ssh/id_ed25519.pub
# Copy and add to GitHub > Settings > SSH Keys

# Test connection
ssh -T git@github.com
```

### Workspace init script doesn't find projects

**Problem**: Workspace directory empty or OpenClaw not fully deployed

**Solution**: Create a project via OpenClaw first, then run the script.

### Cron job not running

**Check cron logs**:

```bash
grep CRON /var/log/syslog | tail -20
```

**Verify cron is installed**:

```bash
sudo systemctl status cron
```

## Variables

See [defaults/main.yml](defaults/main.yml) for all configurable variables:

- `openclaw_backup_dir` - Where backups are stored (default: `~/openclaw-backups`)
- `openclaw_backup_repo` - Git repo URL (leave empty to disable)
- `openclaw_backup_cron_*` - Cron schedule settings
