# Proxmox Setup Guide for OpenClaw

This guide will help you prepare your Proxmox environment for automated OpenClaw deployment.

## Prerequisites

- Proxmox VE 7.0 or higher installed and configured
- Network connectivity to Proxmox host
- Administrative access to Proxmox

## Step 1: Create API Token

1. Log into Proxmox web interface
2. Navigate to **Datacenter → Permissions → API Tokens**
3. Click **Add**
4. Fill in the details:
   - User: `root@pam`
   - Token ID: `terraform` (or your preferred name)
   - Privilege Separation: **Unchecked** (for full access)
5. Click **Add**
6. **Important**: Copy the token secret - it won't be shown again!

## Step 2: Create Ubuntu Cloud-Init Template (Recommended)

### Option A: Using Ubuntu Cloud Image (Faster)

```bash
# SSH to your Proxmox host
ssh root@your-proxmox-host

# Download Ubuntu 22.04 cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create a VM (ID 9000, you can change this)
qm create 9000 --name ubuntu-2204-cloudinit --memory 2048 --net0 virtio,bridge=vmbr0

# Import the disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configure the VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000

# Clean up
rm jammy-server-cloudimg-amd64.img
```

### Option B: Using Standard ISO

1. Download Ubuntu 22.04 ISO
2. Upload to Proxmox storage
3. Create VM manually through web interface
4. Install Ubuntu with minimal configuration
5. Install cloud-init: `apt-get install cloud-init`
6. Clean up and convert to template

## Step 3: Configure Network Bridge

Ensure your Proxmox host has a network bridge configured:

1. Navigate to **Datacenter → Node → Network**
2. Verify `vmbr0` or your preferred bridge exists
3. Note the bridge name for Terraform configuration

## Step 4: Verify Storage

Check available storage pools:

```bash
pvesm status
```

Common storage names:

- `local-lvm` - LVM thin pool
- `local` - Directory storage
- Custom pools you've configured

Note the storage name for Terraform configuration.

## Step 5: Test API Access

From your local machine:

```bash
# Install curl if needed
curl -k "https://your-proxmox-ip:8006/api2/json/nodes" \
  -H "Authorization: PVEAPIToken=root@pam!terraform=your-secret-token"
```

You should get a JSON response with node information.

## Step 6: Configure Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
proxmox_host              = "192.168.1.100:8006"  # Your Proxmox IP
proxmox_api_token_id      = "root@pam!terraform"  # Your token ID
proxmox_api_token_secret  = "your-secret-from-step1"
proxmox_node              = "pve"  # Your node name (from web UI)

template_name     = "ubuntu-2204-cloudinit"  # Template from Step 2
vm_storage        = "local-lvm"  # Storage from Step 4
vm_network_bridge = "vmbr0"  # Bridge from Step 3
```

## Troubleshooting

### Common Issues

**Problem**: Terraform can't connect to Proxmox API

- Check firewall allows port 8006
- Verify API token has correct permissions
- Ensure `proxmox_tls_insecure = true` for self-signed certs

**Problem**: VM creation fails with permission error

- Ensure API token has VM.\* permissions on /
- Check storage quota isn't exceeded

**Problem**: Cloud-init not working

- Verify cloud-init is installed in template
- Check cloudinit disk is added to VM
- Ensure network bridge allows DHCP (or use static IP)

### Useful Commands

```bash
# List all VMs
qm list

# Show VM configuration
qm config <vmid>

# Start VM
qm start <vmid>

# View VM console
qm terminal <vmid>

# Delete VM
qm destroy <vmid>
```

## Security Recommendations

1. **Use separate API token** instead of root password
2. **Limit token permissions** to only what's needed:
   - VM.Allocate, VM.Config.\*, VM.Console, VM.PowerMgmt
   - Datastore.Allocate, Datastore.AllocateSpace
3. **Use private network** for VM management
4. **Enable firewall** on Proxmox
5. **Regular backups** of important VMs

## Next Steps

Once Proxmox is configured, you can proceed with deployment:

```bash
./scripts/setup.sh
./scripts/deploy.sh
```

## Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
