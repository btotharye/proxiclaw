# Contributing to OpenClaw Deployment

## Project Structure

```
openclaw/
├── terraform/              # Infrastructure provisioning
│   ├── main.tf            # Main Terraform config
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── terraform.tfvars   # Your values (not committed)
│
├── ansible/               # Configuration management
│   ├── ansible.cfg        # Ansible configuration
│   ├── inventory/         # Inventory files
│   │   ├── hosts          # Host definitions
│   │   └── group_vars/    # Group variables
│   ├── playbooks/         # Playbooks
│   │   ├── site.yml       # Main playbook
│   │   └── *.yml          # Additional playbooks
│   └── roles/             # Ansible roles
│       ├── common/        # Common system setup
│       ├── docker/        # Docker installation
│       └── openclaw/      # Application deployment
│
├── scripts/               # Helper scripts
│   ├── setup.sh          # Initial setup
│   ├── deploy.sh         # Deployment script
│   └── manage.sh         # Management script
│
└── docs/                 # Documentation
    ├── PROXMOX_SETUP.md  # Proxmox preparation
    ├── DEPLOYMENT.md     # Deployment guide
    └── REQUIREMENTS.md   # Requirements list
```

## Customization Points

### 1. Terraform Configuration

Modify [terraform/variables.tf](terraform/variables.tf) to add new VM options:

```hcl
variable "new_option" {
  description = "Description"
  type        = string
  default     = "value"
}
```

Update [terraform/main.tf](terraform/main.tf) to use the variable.

### 2. Ansible Roles

Add new roles in `ansible/roles/`:

```bash
mkdir -p ansible/roles/myrole/{tasks,handlers,templates,files}
```

Create [ansible/roles/myrole/tasks/main.yml](ansible/roles/myrole/tasks/main.yml):

```yaml
---
- name: My task
  apt:
    name: mypackage
    state: present
```

Add role to [ansible/playbooks/site.yml](ansible/playbooks/site.yml):

```yaml
roles:
  - common
  - docker
  - myrole
  - openclaw
```

### 3. Docker Compose Template

Modify [ansible/roles/openclaw/templates/docker-compose.yml.j2](ansible/roles/openclaw/templates/docker-compose.yml.j2) to add services:

```yaml
services:
  newservice:
    image: myimage:latest
    ports:
      - "3000:3000"
    environment:
      KEY: value
```

### 4. Environment Variables

Add variables to [ansible/inventory/group_vars/all.yml](ansible/inventory/group_vars/all.yml):

```yaml
my_new_var: "value"
```

Use in templates:

```
{{ my_new_var }}
```

## Adding Features

### Add a New Service (e.g., PostgreSQL)

1. Update [ansible/roles/openclaw/templates/docker-compose.yml.j2](ansible/roles/openclaw/templates/docker-compose.yml.j2):

```yaml
postgres:
  image: postgres:15
  environment:
    POSTGRES_USER: openclaw
    POSTGRES_PASSWORD: ${DB_PASSWORD}
    POSTGRES_DB: openclaw
  volumes:
    - postgres-data:/var/lib/postgresql/data
```

2. Add variables to [ansible/inventory/group_vars/all.yml](ansible/inventory/group_vars/all.yml):

```yaml
openclaw_env_vars:
  DATABASE_URL: "postgresql://openclaw:password@postgres:5432/openclaw"
```

3. Update firewall rules if needed:

```yaml
ufw_allow_ports:
  - "5432"
```

### Add Monitoring

Create a new role `ansible/roles/monitoring/`:

```yaml
# tasks/main.yml
- name: Install Prometheus
  # ... tasks

- name: Install Grafana
  # ... tasks
```

### Add SSL/TLS

1. Create role `ansible/roles/nginx/`
2. Add Let's Encrypt with certbot
3. Configure reverse proxy

Example structure:

```yaml
# roles/nginx/tasks/main.yml
- name: Install nginx
  apt:
    name: nginx
    state: present

- name: Configure nginx
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/openclaw
  notify: reload nginx
```

## Testing Changes

### Test Terraform Changes

```bash
cd terraform
terraform fmt      # Format code
terraform validate # Validate syntax
terraform plan     # Preview changes
```

### Test Ansible Changes

```bash
cd ansible

# Check syntax
ansible-playbook --syntax-check playbooks/site.yml

# Dry run
ansible-playbook -i inventory/hosts playbooks/site.yml --check

# Run specific role
ansible-playbook -i inventory/hosts playbooks/site.yml --tags docker

# Verbose output
ansible-playbook -vvv -i inventory/hosts playbooks/site.yml
```

### Test on Development Environment

Create a test inventory:

```bash
cp -r ansible/inventory ansible/inventory-dev
# Edit ansible/inventory-dev/hosts with test VM IP
```

Run against dev:

```bash
ansible-playbook -i ansible/inventory-dev/hosts playbooks/site.yml
```

## Code Style

### Terraform

- Use consistent naming (lowercase, underscores)
- Add descriptions to all variables
- Use meaningful variable names
- Comment complex logic

### Ansible

- Use YAML syntax consistently (2 spaces)
- Name all tasks descriptively
- Use tags for role organization
- Keep playbooks simple, move logic to roles
- Use handlers for service restarts

### Shell Scripts

- Use shellcheck for validation
- Add error handling (`set -e`)
- Use meaningful variable names
- Add usage/help functions
- Use colors for output clarity

## Submitting Changes

1. Test your changes thoroughly
2. Update documentation
3. Follow existing code style
4. Add comments for complex logic
5. Create clear commit messages

## Common Tasks

### Add a Firewall Rule

Edit [ansible/inventory/group_vars/all.yml](ansible/inventory/group_vars/all.yml):

```yaml
ufw_allow_ports:
  - "22"
  - "80"
  - "443"
  - "8080"
  - "9090" # New port
```

### Change Application Port

Edit [ansible/inventory/group_vars/all.yml](ansible/inventory/group_vars/all.yml):

```yaml
openclaw_port: 3000 # Changed from 8080
```

Re-run deployment:

```bash
./scripts/deploy.sh --ansible-only
```

### Add Backup Job

Create [ansible/roles/openclaw/files/backup-cron.sh](ansible/roles/openclaw/files/backup-cron.sh):

```bash
#!/bin/bash
tar -czf /backups/openclaw-$(date +%Y%m%d).tar.gz /var/lib/openclaw
```

Add task in role:

```yaml
- name: Setup backup cron job
  cron:
    name: "Daily OpenClaw backup"
    hour: "2"
    minute: "0"
    job: "/opt/openclaw/backup-cron.sh"
```

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Proxmox API Documentation](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Getting Help

- Check existing documentation in `docs/`
- Review similar implementations in roles/
- Test in development environment first
- Ask for clarification before major changes
