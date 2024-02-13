locals {
  ssh_key = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
}

data "yandex_vpc_network" "default" {
  name = var.vpc_name
}

data "yandex_vpc_subnet" "default" {
  name = var.subnet_name
}

resource "yandex_compute_instance" "instance" {
  name        = var.vm_name
  hostname    = var.vm_name
  platform_id = var.platform_id
  zone        = var.zone
  
  resources {
    cores         = var.cpu
    memory        = var.memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.default.id
    nat                = var.nat
    ip_address         = var.internal_ip_address
    nat_ip_address     = var.nat_ip_address
  }

  metadata = {
    ssh-keys           = local.ssh_key
    user-data          = "${file("cloud-init.yaml")}"
  }
}