.PHONY: help setup deploy deploy-full deploy-vm deploy-config provision-ansible destroy clean test-connection

help:
	@echo "OpenClaw Deployment Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup              - Install dependencies and create config files"
	@echo "  deploy-full        - Full deployment (VM creation via Terraform + Ansible config)"
	@echo "  deploy-vm          - Create VM only with Terraform"
	@echo "  deploy-config      - Configure existing VM with Ansible"
	@echo "  provision-ansible  - Provision VM with Ansible only (no Terraform) + configure"
	@echo "  test-connection    - Test SSH connection to VM"
	@echo "  destroy            - Destroy infrastructure"
	@echo "  clean              - Clean up temporary files"
	@echo ""

setup:
	@echo "Running setup script..."
	./scripts/setup.sh

deploy-full:
	@echo "Starting full deployment..."
	./scripts/deploy.sh --full

deploy-vm:
	@echo "Creating VM with Terraform..."
	./scripts/deploy.sh --terraform-only

deploy-config:
	@echo "Configuring VM with Ansible..."
	./scripts/deploy.sh --ansible-only

provision-ansible:
	@echo "Provisioning VM with Ansible (no Terraform)..."
	./scripts/deploy.sh --ansible-provision

test-connection:
	@echo "Testing Ansible connection..."
	cd ansible && ansible openclaw -m ping

destroy:
	@echo "Destroying infrastructure..."
	./scripts/deploy.sh --destroy

clean:
	@echo "Cleaning up..."
	rm -rf terraform/.terraform
	rm -f terraform/.terraform.lock.hcl
	rm -f terraform/terraform.tfstate*
	rm -f ansible/*.retry
	@echo "Clean complete"

# Development targets
dev-plan:
	@echo "Planning Terraform changes..."
	cd terraform && terraform plan

dev-apply:
	@echo "Applying Terraform changes..."
	cd terraform && terraform apply

dev-ansible-check:
	@echo "Running Ansible in check mode..."
	cd ansible && ansible-playbook -i inventory/hosts playbooks/site.yml --check

dev-ansible-verbose:
	@echo "Running Ansible with verbose output..."
	cd ansible && ansible-playbook -vvv -i inventory/hosts playbooks/site.yml
