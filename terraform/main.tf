terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://${var.proxmox_host}"
  insecure  = var.proxmox_tls_insecure
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  
  ssh {
    agent    = true
    username = "root"
  }
}

# Cloud-init user data to install guest agent and configure system
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - name: ${var.vm_user}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(file(var.ssh_public_key_file))}
    packages:
      - qemu-guest-agent
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
    EOF

    file_name = "cloud-init-${var.vm_name}.yaml"
  }
}

# Create VM for OpenClaw
resource "proxmox_virtual_environment_vm" "openclaw" {
  name        = var.vm_name
  node_name   = var.proxmox_node
  description = "OpenClaw Application Server"

  # Clone from template
  clone {
    vm_id = tonumber(var.template_name)
    full  = true
  }

  # CPU and Memory
  cpu {
    cores   = var.vm_cores
    sockets = var.vm_sockets
  }

  memory {
    dedicated = var.vm_memory
  }

  # Network
  network_device {
    bridge = var.vm_network_bridge
    model  = "virtio"
  }

  # Disk resize
  disk {
    interface    = "scsi0"
    size         = tonumber(regex("^([0-9]+)", var.vm_disk_size)[0])
    datastore_id = var.vm_storage
    iothread     = true
  }

  # Cloud-init configuration
  initialization {
    datastore_id = var.vm_storage
    
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id

    ip_config {
      ipv4 {
        address = var.vm_ip_config != "" ? var.vm_ip_config : "dhcp"
      }
    }
  }

  # VM Agent
  agent {
    enabled = true
  }

  # Start on boot
  on_boot = true

  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
