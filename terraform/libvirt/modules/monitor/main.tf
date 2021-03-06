resource "libvirt_volume" "monitor_image_disk" {
    count            = var.monitor_enabled == true ? 1 : 0
    name             = "${terraform.workspace}-${var.name}-disk"
    source           = var.source_image
    base_volume_name = var.volume_name
    pool             = var.storage_pool
}

resource "libvirt_domain" "monitor_domain" {
    name       = "${terraform.workspace}-${var.name}"
    count      = var.monitor_enabled == true ? 1 : 0
    memory     = var.memory
    vcpu       = var.cpus
    qemu_agent = true

    disk {
        volume_id = libvirt_volume.monitor_image_disk.0.id
    }

    network_interface {
        wait_for_lease = true
        network_name   = var.nat_network_name
        bridge         = var.bridge
        mac            = var.mac
    }

    network_interface {
        wait_for_lease = false
        network_name   = var.isolated_network_name
        network_id     = var.isolated_network_id
        hostname       = "${terraform.workspace}-${var.name}"
        addresses      = [var.monitor_private_ip]
    }

    console {
        type        = "pty"
        target_port = "0"
        target_type = "serial"
    }

    console {
        type        = "pty"
        target_type = "virtio"
        target_port = "1"
    }

    graphics {
        type        = "spice"
        listen_type = "address"
        autoport    = true
    }

    cpu = {
        mode = "host-passthrough"
    }
}

output "output_data" {
    value = {
        id         = join("", libvirt_domain.monitor_domain.*.id)
        hostname   = join("", libvirt_domain.monitor_domain.*.name)
        private_ip = var.monitor_private_ip
        public_ip  = join("", libvirt_domain.monitor_domain.*.network_interface.0.addresses.0)
    }
}
