#!/bin/bash

# OpenClaw Management Script
# Provides convenient commands for managing the deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get VM IP from inventory
get_vm_ip() {
    if [ -f ansible/inventory/hosts ]; then
        grep -v "^\[" ansible/inventory/hosts | grep -v "^#" | grep -v "^$" | head -n1 | awk '{print $1}'
    else
        echo ""
    fi
}

VM_IP=$(get_vm_ip)

# Display help
show_help() {
    cat << EOF
OpenClaw Management Script

Usage: ./scripts/manage.sh [COMMAND]

Commands:
  status      - Show status of all services
  logs        - View application logs
  restart     - Restart all services
  stop        - Stop all services
  start       - Start all services
  ssh         - SSH into the VM
  update      - Update application to latest version
  backup      - Create backup of data
  restore     - Restore from backup
  scale       - Scale application (requires args)
  health      - Check application health
  clean       - Clean up old containers and images

Examples:
  ./scripts/manage.sh status
  ./scripts/manage.sh logs
  ./scripts/manage.sh ssh

EOF
}

# Check if VM IP is available
check_vm() {
    if [ -z "$VM_IP" ]; then
        echo -e "${RED}Error: Cannot determine VM IP${NC}"
        echo "Make sure ansible/inventory/hosts is configured"
        exit 1
    fi
}

# Show status
show_status() {
    check_vm
    echo -e "${BLUE}Checking OpenClaw status on $VM_IP...${NC}"
    ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose ps"
}

# View logs
view_logs() {
    check_vm
    echo -e "${BLUE}Viewing logs from $VM_IP...${NC}"
    echo "Press Ctrl+C to exit"
    ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose logs -f --tail=100"
}

# Restart services
restart_services() {
    check_vm
    echo -e "${YELLOW}Restarting services on $VM_IP...${NC}"
    ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose restart"
    echo -e "${GREEN}✓ Services restarted${NC}"
}

# Stop services
stop_services() {
    check_vm
    echo -e "${YELLOW}Stopping services on $VM_IP...${NC}"
    ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose stop"
    echo -e "${GREEN}✓ Services stopped${NC}"
}

# Start services
start_services() {
    check_vm
    echo -e "${YELLOW}Starting services on $VM_IP...${NC}"
    ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose up -d"
    echo -e "${GREEN}✓ Services started${NC}"
}

# SSH into VM
ssh_vm() {
    check_vm
    echo -e "${BLUE}Connecting to $VM_IP...${NC}"
    ssh ubuntu@$VM_IP
}

# Update application
update_app() {
    check_vm
    echo -e "${YELLOW}Updating OpenClaw on $VM_IP...${NC}"
    cd ansible
    ansible-playbook -i inventory/hosts playbooks/site.yml --tags openclaw
    echo -e "${GREEN}✓ Update complete${NC}"
}

# Create backup
create_backup() {
    check_vm
    BACKUP_NAME="openclaw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo -e "${YELLOW}Creating backup: $BACKUP_NAME${NC}"
    ssh ubuntu@$VM_IP "sudo tar -czf /tmp/$BACKUP_NAME /var/lib/openclaw /opt/openclaw/.env"
    echo -e "${YELLOW}Downloading backup...${NC}"
    scp ubuntu@$VM_IP:/tmp/$BACKUP_NAME ./backups/
    ssh ubuntu@$VM_IP "rm /tmp/$BACKUP_NAME"
    echo -e "${GREEN}✓ Backup saved to: ./backups/$BACKUP_NAME${NC}"
}

# Check health
check_health() {
    check_vm
    OPENCLAW_PORT=$(grep openclaw_port ansible/inventory/group_vars/all.yml | awk '{print $2}' || echo "8080")
    echo -e "${BLUE}Checking health of OpenClaw...${NC}"
    
    # Check if service is responding
    if curl -f -s http://$VM_IP:$OPENCLAW_PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Application is healthy${NC}"
    else
        echo -e "${YELLOW}⚠ Application health check failed${NC}"
        echo "  Checking service status..."
        ssh ubuntu@$VM_IP "cd /opt/openclaw && docker-compose ps"
    fi
}

# Clean up
cleanup() {
    check_vm
    echo -e "${YELLOW}Cleaning up unused containers and images on $VM_IP...${NC}"
    ssh ubuntu@$VM_IP "docker system prune -f"
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Create backups directory
mkdir -p backups

# Parse command
case "${1:-}" in
    status)
        show_status
        ;;
    logs)
        view_logs
        ;;
    restart)
        restart_services
        ;;
    stop)
        stop_services
        ;;
    start)
        start_services
        ;;
    ssh)
        ssh_vm
        ;;
    update)
        update_app
        ;;
    backup)
        create_backup
        ;;
    health)
        check_health
        ;;
    clean)
        cleanup
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
