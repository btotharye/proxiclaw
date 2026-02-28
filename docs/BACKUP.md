# OpenClaw Backup Guide

This guide explains how to back up your OpenClaw configuration, workspace metadata, and projects using the automated backup system.

## Table of Contents

- [Overview](#overview)
- [Three-Tier Backup Strategy](#three-tier-backup-strategy)
- [Quick Setup](#quick-setup)
- [Configuration Backups](#configuration-backups)
- [Workspace Project Repos](#workspace-project-repos)
- [VM Snapshots](#vm-snapshots)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

OpenClaw stores several types of data that you'll want to protect:

| Type           | Location                                           | Backup Method                  |
| -------------- | -------------------------------------------------- | ------------------------------ |
| Configuration  | `~/.openclaw/*.json`                               | Automated git backups          |
| API Keys       | `~/.openclaw/agents/main/agent/auth-profiles.json` | **NOT backed up** (regenerate) |
| Workspace Code | `~/.openclaw/workspace/*/`                         | Per-project git repos          |
| AI Guardrails  | `~/.openclaw/workspace/*/.cursorrules`             | Included in project repos      |
| Chat History   | `~/.openclaw/agents/main/sessions/*.jsonl`         | Optional (usually not needed)  |
| Device Pairing | `~/.openclaw/devices/paired.json`                  | Automated git backups          |

## Three-Tier Backup Strategy

### Tier 1: Configuration Backups (Automated)

**Purpose:** Daily automated backups of OpenClaw settings and workspace metadata

**What's included:**

- Main configuration (`openclaw.json`)
- Device pairing information
- Workspace `.cursorrules` files
- Backup manifest with timestamps

**What's excluded:**

- API keys (security - never committed)
- SSH keys and certificates
- Log files
- Actual workspace code (handled separately)

**Schedule:** Daily at 2 AM (configurable)

### Tier 2: Workspace Projects (Manual Setup)

**Purpose:** Version control for your actual code projects

**How it works:**

- Each workspace project is its own git repository
- `.cursorrules` files are included with the code
- Standard git workflow (commit, push, pull)
- Clone and work from any machine

**Use the init script:**

```bash
ssh ubuntu@<vm-ip>
~/bin/init-workspace-repos.sh
```

### Tier 3: VM Snapshots (Recommended)

**Purpose:** Complete system state for disaster recovery

**Recommended schedule:**

- Before major OpenClaw upgrades
- Weekly full VM snapshots (via Proxmox)
- Before significant configuration changes

**Create a snapshot:**

```bash
# From your local machine
ssh root@proxmox-host "qm snapshot <vm-id> backup-$(date +%Y%m%d)"
```

## Quick Setup

### 1. Create Backup Repository

```bash
# On GitHub, create a PRIVATE repository
# Name: openclaw-config-backup
# Visibility: Private (important!)
```

### 2. Configure Ansible

Edit `ansible/inventory/group_vars/all.yml`:

```yaml
# Backup configuration
openclaw_backup_repo: "git@github.com:yourusername/openclaw-config-backup.git"

# Optional: customize schedule (default: daily at 2 AM)
openclaw_backup_cron_hour: "2"
openclaw_backup_cron_minute: "0"
```

### 3. Deploy

```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/site.yml
```

The backup role will:

- ✓ Create `~/openclaw-backups` directory
- ✓ Initialize git repository
- ✓ Create backup script
- ✓ Set up cron job for daily backups
- ✓ Install workspace init script
- ✓ Run initial backup

## Configuration Backups

### Manual Backup

Run a backup anytime:

```bash
ssh ubuntu@<vm-ip>
~/openclaw-backups/backup.sh
```

### Check Backup Status

View recent backups:

```bash
ssh ubuntu@<vm-ip>
cd ~/openclaw-backups
git log --oneline -10
```

View backup logs:

```bash
ssh ubuntu@<vm-ip>
tail -50 ~/openclaw-backups/backup.log
```

### Verify Cron Job

```bash
ssh ubuntu@<vm-ip>
crontab -l | grep openclaw
```

Output should show:

```
0 2 * * * /home/ubuntu/openclaw-backups/backup.sh >> /home/ubuntu/openclaw-backups/backup.log 2>&1
```

### Restore from Backup

If you need to restore configuration:

```bash
# On the VM
cd ~/openclaw-backups
git checkout <commit-hash>  # or just use latest

# Copy files back
cp config/openclaw.json ~/.openclaw/
cp config/devices/paired.json ~/.openclaw/devices/

# Restart OpenClaw
cd /opt/openclaw
docker compose restart openclaw-gateway
```

**Note:** You'll need to reconfigure API keys manually (never backed up for security).

## Workspace Project Repos

### Initialize All Workspace Projects

Run the automated script:

```bash
ssh ubuntu@<vm-ip>
~/bin/init-workspace-repos.sh
```

This will:

- ✓ Initialize git in each workspace project
- ✓ Create `.gitignore` files
- ✓ Create `README.md` templates
- ✓ Include `.cursorrules` files
- ✓ Make initial commits
- ✓ Show instructions for pushing to GitHub

### Push Projects to GitHub

For each project:

```bash
# 1. Create GitHub repo
# Go to GitHub and create a repo with the same name as your project

# 2. On the VM, add remote
ssh ubuntu@<vm-ip>
cd ~/.openclaw/workspace/my-project
git remote add origin git@github.com:yourusername/my-project.git
git push -u origin main
```

### Clone Locally

Work on projects from your Mac:

```bash
# On your Mac
git clone git@github.com:yourusername/my-project.git
cd my-project

# Make changes
git add .
git commit -m "Updated feature"
git push
```

Changes sync between:

- ✓ Your Mac
- ✓ GitHub
- ✓ OpenClaw workspace (if you pull)

### Recommended Workflow

```bash
# Option A: Work via OpenClaw (on VM)
# - Edit in OpenClaw web interface
# - OpenClaw commits/pushes automatically
# - Pull changes locally when needed

# Option B: Work locally (on Mac)
# - Clone to your Mac
# - Edit with your favorite IDE
# - Commit and push
# - OpenClaw uses latest from GitHub

# Option C: Hybrid
# - Quick edits in OpenClaw
# - Major work locally on Mac
# - Both push to same GitHub repo
```

## VM Snapshots

### Create Snapshot

Using Proxmox CLI:

```bash
# From Proxmox host
ssh root@proxmox-host
qm snapshot <vm-id> before-upgrade-$(date +%Y%m%d)

# Example
qm snapshot 101 before-upgrade-20260228
```

### List Snapshots

```bash
ssh root@proxmox-host
qm listsnapshot <vm-id>
```

### Rollback to Snapshot

```bash
ssh root@proxmox-host
qm rollback <vm-id> <snapshot-name>
```

**Warning:** This will revert the ENTIRE VM to the snapshot state. You'll lose any changes made after the snapshot.

### Automated Weekly Snapshots

Add to Proxmox host crontab:

```bash
# On Proxmox host
crontab -e

# Add weekly snapshot (Sundays at 3 AM)
0 3 * * 0 /usr/sbin/qm snapshot 101 weekly-$(date +\%Y\%m\%d) && /usr/sbin/qm delsnapshot 101 weekly-$(date -d '4 weeks ago' +\%Y\%m\%d) 2>/dev/null
```

## Best Practices

### DO ✅

1. **Keep backup repo private** - Contains device pairing info
2. **Initialize workspace projects early** - Set up git from day one
3. **Take snapshots before upgrades** - Easy rollback if needed
4. **Test restore process** - Verify backups work before you need them
5. **Use meaningful commit messages** - When manually committing projects
6. **Push projects to GitHub** - Don't rely only on VM storage
7. **Separate secrets** - API keys in Ansible vault, not in repos

### DON'T ❌

1. **Don't commit API keys** - The backup script explicitly excludes them
2. **Don't rely on one backup** - Use all three tiers
3. **Don't snapshot while system is busy** - Use `qm snapshot --vmstate` or stop running processes
4. **Don't delete all snapshots** - Keep at least 2-3 recent ones
5. **Don't forget SSH keys** - Backup repo needs SSH access
6. **Don't backup to same physical disk** - Consider off-host backup storage

### Backup Schedule Recommendations

| Backup Type       | Frequency          | Retention              |
| ----------------- | ------------------ | ---------------------- |
| Config backups    | Daily (automated)  | Keep all (small files) |
| Workspace commits | After each feature | Keep all (git history) |
| VM snapshots      | Weekly             | Keep last 4 weeks      |
| Full VM backup    | Monthly            | Keep last 3 months     |

## Troubleshooting

### Backup Script Fails to Push

**Problem:** `fatal: Could not read from remote repository`

**Solution:** Set up SSH keys for GitHub on the VM

```bash
ssh ubuntu@<vm-ip>

# Generate SSH key
ssh-keygen -t ed25519 -C "openclaw-backup@your-vm"

# Display public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: Settings > SSH and GPG keys > New SSH key

# Test connection
ssh -T git@github.com
```

### Cron Job Not Running

**Check if cron is running:**

```bash
ssh ubuntu@<vm-ip>
sudo systemctl status cron
```

**Check cron logs:**

```bash
ssh ubuntu@<vm-ip>
grep CRON /var/log/syslog | tail -20
```

**Verify cron syntax:**

```bash
crontab -l
```

**Manual test:**

```bash
ssh ubuntu@<vm-ip>
~/openclaw-backups/backup.sh
```

### Workspace Init Script Finds No Projects

**Problem:** "No projects found in workspace"

**Solution:** Create a project in OpenClaw first

```bash
# In OpenClaw web interface, create a new project
# Then run the init script
ssh ubuntu@<vm-ip>
~/bin/init-workspace-repos.sh
```

### Git Push Requires Password

**Problem:** GitHub asks for username/password when pushing

**Solution:** You're using HTTPS URL instead of SSH

```bash
# Change to SSH URL
cd ~/.openclaw/workspace/your-project
git remote set-url origin git@github.com:yourusername/your-project.git

# Verify
git remote -v
```

### Restore Doesn't Work

**Problem:** Configuration restored but OpenClaw behaves differently

**Checklist:**

1. ✓ API keys reconfigured? (not backed up)
2. ✓ Docker containers restarted? (`docker compose restart`)
3. ✓ File permissions correct? (`chown ubuntu:ubuntu ~/.openclaw -R`)
4. ✓ Workspace code also restored? (separate from config)

---

## Additional Resources

- [Backup Role Documentation](../ansible/roles/openclaw-backup/README.md)
- [Common Commands](COMMON_COMMANDS.md)
- [Getting Started Guide](GETTING_STARTED.md)
- [Proxmox Snapshot Documentation](https://pve.proxmox.com/wiki/VM_Snapshots)
- [GitHub SSH Key Setup](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
