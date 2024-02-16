output "vm_ip" {
  value = yandex_compute_instance.instance.network_interface.0.nat_ip_address 
}

output "vm_private_ip" {
  value = yandex_compute_instance.instance.network_interface.0.ip_address 
}