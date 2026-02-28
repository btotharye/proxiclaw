# Proxmox Connection
variable "proxmox_host" {
  description = "Proxmox host address with port (e.g., 192.168.1.100:8006)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID (e.g., root@pam!terraform)"
  type        = string
  default     = ""
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification (useful for self-signed certs)"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name to create VM on"
  type        = string
}

# VM Configuration
variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "openclaw-vm"
}

variable "template_name" {
  description = "VM ID of the cloud-init template to clone (e.g., '9000')"
  type        = string
  default     = "9000"
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "vm_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "vm_disk_size" {
  description = "Disk size (e.g., '50G')"
  type        = string
  default     = "50G"
}

variable "vm_storage" {
  description = "Storage location for VM disk (e.g., local-lvm, local-zfs, local)"
  type        = string
  default     = "local-lvm"
}

variable "vm_network_bridge" {
  description = "Network bridge to use"
  type        = string
  default     = "vmbr0"
}

variable "vm_ip_config" {
  description = "IP configuration (e.g., 'ip=192.168.1.100/24,gw=192.168.1.1' or leave empty for DHCP)"
  type        = string
  default     = ""
}

# Cloud-init settings
variable "vm_user" {
  description = "Default user for cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "vm_password" {
  description = "Password for default user (optional if using SSH keys)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key_file" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
