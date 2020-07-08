resource "libvirt_volume" "monitor_image_disk" {
    count            = var.enabled ? 1 : 0
    name             = "${terraform.workspace}-monitor-disk"
    pool             = var.storage_pool
    source           = var.source_image
    base_volume_name = var.volume_name
}

resource "libvirt_domain" "monitor_domain" {
    count      = var.enabled ? 1 : 0
    name       = "${terraform.workspace}-monitor"
    vcpu       = var.cpus
    memory     = var.memory
    qemu_agent = true

    disk {
        volume_id = libvirt_volume.monitor_image_disk.0.id
    }

    network_interface {
        wait_for_lease = true
        network_id     = var.public_network_id
        bridge         = var.public_bridge
    }

    network_interface {
        wait_for_lease = false
        network_id     = var.private_network_id
        hostname       = "${terraform.workspace}-monitor"
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
