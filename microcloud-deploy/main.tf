terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
    ssh = {
      source = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "lxd" {
}
provider ssh {
  # Configuration options
}
locals {
  cloud_init = <<EOT
#cloud-config
users:
  - name: ubuntu
    ssh_authorized_keys:
    - ${var.ssh_pubkey}
    sudo: ALL=(ALL) NOPASSWD:ALL
# TODO: Re-add hardening
snap:
  commands:
    00: snap refresh lxd --channel=5.21/stable --cohort="+"
    01: snap install microceph --channel=quincy/stable --cohort="+"
    02: snap install microovn --channel=22.03/stable --cohort="+"
    03: snap install microcloud --channel=latest/stable --cohort="+"
EOT
}
resource "lxd_project" "microcloud" {
  name        = "microcloud"
  description = "Your Microcloud!"
  config = {
    "features.storage.volumes" = true
    "features.images"          = true
    "features.profiles"        = true
  }
}

resource "lxd_volume" "mc_sdb_vols" {
  count = 3
  name = "microcloud-sdb-${count.index}"
  content_type = "block"
  pool = "default"
  project = "microcloud"
}
resource "lxd_instance" "microcloud_nodes" {
  count            = 3
  name             = "microcloud-${count.index}"
  image            = "ubuntu:jammy"
  type             = "virtual-machine"
  project          = lxd_project.microcloud.name
  wait_for_network = false
  config = {
    "boot.autostart"       = true
    "cloud-init.user-data" = local.cloud_init
  }

  limits = {
    cpu    = 4
    memory = "8GiB"
  }
  device {
    name = "root"
    type = "disk"
    properties = {
      pool = "default"
      path = "/"
      size = "200GiB"
    }
  }
  device {
    name = "sdb"
    type = "disk"
    properties = {
      pool = "default"
      source = lxd_volume.mc_sdb_vols[count.index].name
    }
  }
  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "bridged"
      parent  = "br0"
    }
  }
}

resource "ssh_resource" "microcloud_init" {
  host         = lxd_instance.microcloud_nodes[0].ipv4_address
  user         = "ubuntu"
  agent        = true

  when         = "create" # Default

  file {
    content     = templatefile("${path.module}/templates/mc-init.tmpl", { instances = [for i in lxd_instance.microcloud_nodes : i.ipv4_address], lookup_subnet = var.lookup_subnet, bridge_nic = var.bridge_nic, bridge_nic_cidr = var.lookup_subnet, ovn_gateway = var.ovn_gateway, ovn_range_start = var.ovn_range_start, ovn_range_end = var.ovn_range_end })
    destination = "/home/ubuntu/init-mc.yaml"
    permissions = "0600"
  }
    commands = [
    "/home/ubuntu/init-mc.yaml | microcloud init --preseed",
  ]
}
