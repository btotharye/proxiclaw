output "vm_id" {
  description = "ID of the created VM"
  value       = proxmox_virtual_environment_vm.openclaw.id
}

output "vm_name" {
  description = "Name of the VM"
  value       = proxmox_virtual_environment_vm.openclaw.name
}

output "vm_ip_address" {
  description = "IP address of the VM"
  value       = try(proxmox_virtual_environment_vm.openclaw.ipv4_addresses[1][0], "Check Proxmox console for IP")
}

output "ssh_connection_string" {
  description = "SSH connection string for the VM"
  value       = "ssh ${var.vm_user}@${try(proxmox_virtual_environment_vm.openclaw.ipv4_addresses[1][0], "VM-IP")}"
}

output "ansible_inventory_entry" {
  description = "Entry to add to Ansible inventory"
  value       = <<-EOT
    [openclaw]
    ${try(proxmox_virtual_environment_vm.openclaw.ipv4_addresses[1][0], "VM-IP-ADDRESS")} ansible_user=${var.vm_user} ansible_ssh_private_key_file=~/.ssh/id_rsa
  EOT
}
