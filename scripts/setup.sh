#!/bin/bash

set -e

echo "==================================="
echo "OpenClaw Deployment Setup Script"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    PACKAGE_MANAGER="brew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PACKAGE_MANAGER="apt-get"
else
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install prerequisites
echo "Checking prerequisites..."

# Check Terraform
if ! command_exists terraform; then
    echo -e "${YELLOW}Terraform not found. Installing...${NC}"
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    else
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install terraform
    fi
else
    echo -e "${GREEN}✓ Terraform installed${NC}"
fi

# Check Ansible
if ! command_exists ansible; then
    echo -e "${YELLOW}Ansible not found. Installing...${NC}"
    if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
        brew install ansible
    else
        sudo apt-add-repository ppa:ansible/ansible -y
        sudo apt-get update
        sudo apt-get install ansible -y
    fi
else
    echo -e "${GREEN}✓ Ansible installed${NC}"
fi

# Check Python
if ! command_exists python3; then
    echo -e "${RED}Python 3 is required but not installed${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Python 3 installed${NC}"
fi

# Install Ansible community collection for Docker
echo ""
echo "Installing Ansible collections..."
ansible-galaxy collection install community.docker

# Setup SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${YELLOW}SSH key not found. Generating...${NC}"
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo -e "${GREEN}✓ SSH key generated${NC}"
else
    echo -e "${GREEN}✓ SSH key exists${NC}"
fi

# Create configuration files from examples
echo ""
echo "Setting up configuration files..."

if [ ! -f terraform/terraform.tfvars ]; then
    cp terraform/terraform.tfvars.example terraform/terraform.tfvars
    echo -e "${GREEN}✓ Created terraform/terraform.tfvars${NC}"
    echo -e "${YELLOW}  >> Please edit terraform/terraform.tfvars with your Proxmox details${NC}"
else
    echo -e "${GREEN}✓ terraform/terraform.tfvars already exists${NC}"
fi

if [ ! -f ansible/inventory/hosts ]; then
    cp ansible/inventory/hosts.example ansible/inventory/hosts
    echo -e "${GREEN}✓ Created ansible/inventory/hosts${NC}"
    echo -e "${YELLOW}  >> Please edit ansible/inventory/hosts with your VM IP after Terraform creates it${NC}"
else
    echo -e "${GREEN}✓ ansible/inventory/hosts already exists${NC}"
fi

echo ""
echo -e "${GREEN}==================================="
echo "Setup Complete!"
echo "===================================${NC}"
echo ""
echo "Next steps:"
echo "1. Edit terraform/terraform.tfvars with your Proxmox credentials"
echo "2. Run: ./scripts/deploy.sh"
echo ""
