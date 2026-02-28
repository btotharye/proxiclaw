#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==================================="
echo "OpenClaw Deployment Script"
echo "===================================${NC}"
echo ""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --full              Full deployment (Terraform + Ansible)"
    echo "  --terraform-only    Only create VM with Terraform"
    echo "  --ansible-only      Only run Ansible configuration"
    echo "  --destroy           Destroy infrastructure"
    echo "  -h, --help          Show this help message"
    echo ""
    exit 1
}

# Parse arguments
FULL_DEPLOY=false
TERRAFORM_ONLY=false
ANSIBLE_ONLY=false
DESTROY=false

if [ $# -eq 0 ]; then
    FULL_DEPLOY=true
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --full)
            FULL_DEPLOY=true
            shift
            ;;
        --terraform-only)
            TERRAFORM_ONLY=true
            shift
            ;;
        --ansible-only)
            ANSIBLE_ONLY=true
            shift
            ;;
        --destroy)
            DESTROY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Destroy infrastructure
if [ "$DESTROY" = true ]; then
    echo -e "${YELLOW}⚠ WARNING: This will destroy your infrastructure!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        cd terraform
        terraform destroy
        cd ..
        echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
    else
        echo "Cancelled"
    fi
    exit 0
fi

# Terraform deployment
if [ "$FULL_DEPLOY" = true ] || [ "$TERRAFORM_ONLY" = true ]; then
    echo -e "${BLUE}Step 1: Creating VM with Terraform${NC}"
    
    if [ ! -f terraform/terraform.tfvars ]; then
        echo -e "${RED}Error: terraform/terraform.tfvars not found${NC}"
        echo "Please run ./scripts/setup.sh first"
        exit 1
    fi
    
    cd terraform
    terraform init
    terraform plan
    
    read -p "Do you want to proceed with VM creation? (yes/no): " proceed
    if [ "$proceed" != "yes" ]; then
        echo "Cancelled"
        exit 0
    fi
    
    terraform apply -auto-approve
    
    # Get VM IP from Terraform output
    VM_IP=$(terraform output -raw vm_ip_address 2>/dev/null || echo "")
    
    cd ..
    
    if [ -n "$VM_IP" ] && [ "$VM_IP" != "null" ]; then
        echo -e "${GREEN}✓ VM created successfully${NC}"
        echo -e "VM IP: ${GREEN}$VM_IP${NC}"
        
        # Update Ansible inventory
        echo "[openclaw]" > ansible/inventory/hosts
        echo "$VM_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa" >> ansible/inventory/hosts
        echo "" >> ansible/inventory/hosts
        echo "[openclaw:vars]" >> ansible/inventory/hosts
        echo "ansible_python_interpreter=/usr/bin/python3" >> ansible/inventory/hosts
        
        echo -e "${GREEN}✓ Updated Ansible inventory${NC}"
        
        # Wait for SSH to be ready
        echo -e "${YELLOW}Waiting for SSH to be ready...${NC}"
        for i in {1..30}; do
            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$VM_IP "echo SSH ready" 2>/dev/null; then
                echo -e "${GREEN}✓ SSH is ready${NC}"
                break
            fi
            echo "Attempt $i/30..."
            sleep 10
        done
    else
        echo -e "${YELLOW}Warning: Could not get VM IP from Terraform${NC}"
        echo "Please check Proxmox console and update ansible/inventory/hosts manually"
        if [ "$TERRAFORM_ONLY" = true ]; then
            exit 0
        fi
        read -p "Press enter to continue with Ansible or Ctrl+C to cancel..."
    fi
    
    if [ "$TERRAFORM_ONLY" = true ]; then
        exit 0
    fi
    
    echo ""
    sleep 5
fi

# Ansible configuration
if [ "$FULL_DEPLOY" = true ] || [ "$ANSIBLE_ONLY" = true ]; then
    echo -e "${BLUE}Step 2: Configuring VM with Ansible${NC}"
    
    if [ ! -f ansible/inventory/hosts ]; then
        echo -e "${RED}Error: ansible/inventory/hosts not found${NC}"
        echo "Please create it from ansible/inventory/hosts.example"
        exit 1
    fi
    
    cd ansible
    
    # Test connectivity
    echo "Testing connectivity..."
    if ! ansible openclaw -m ping; then
        echo -e "${RED}Error: Cannot connect to VM${NC}"
        echo "Please check:"
        echo "  - VM is running"
        echo "  - IP address in ansible/inventory/hosts is correct"
        echo "  - SSH key has access"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Connection successful${NC}"
    echo ""
    
    # Run playbook
    echo "Running Ansible playbook..."
    ansible-playbook -i inventory/hosts playbooks/site.yml
    
    cd ..
    
    echo ""
    echo -e "${GREEN}==================================="
    echo "Deployment Complete!"
    echo "===================================${NC}"
    
    # Get VM IP for final message
    if [ -n "$VM_IP" ]; then
        OPENCLAW_PORT=$(grep openclaw_port ansible/inventory/group_vars/all.yml | awk '{print $2}' || echo "8080")
        echo ""
        echo -e "OpenClaw is now running at: ${GREEN}http://$VM_IP:$OPENCLAW_PORT${NC}"
    fi
fi
