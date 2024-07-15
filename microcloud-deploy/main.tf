terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.0.0"
    }
  }
}

provider "lxd" {
}

locals {
  cloud_init = <<EOT
#cloud-config
users:
  - name: ubuntu
    ssh_authorized_keys:
    - ${var.ssh_pubkey}
    sudo: ALL=(ALL) NOPASSWD:ALL
write_files:
  - content: |
        # `lookup_subnet` limits the subnet when looking up systems with mDNS.
        lookup_subnet: 10.0.0.1/24
        # `lookup_interface` limits the interface when looking up systems with mDNS.
        lookup_interface: eth0

        # `systems` lists the systems we expect to find by their host name.
        #   `name` represents the host name
        #   `ovn_uplink_interface` is optional and represents the name of the interface reserved for use with OVN.
        #   `storage` is optional and represents explicit paths to disks for each system.
        systems:
        - name: microcloud01
        ovn_uplink_interface: ${var.bridge_nic}
        - name: microcloud02
          ovn_uplink_interface: ${var.bridge_nic}
          storage:
              local:
                path: /dev/sda
                wipe: true
              ceph:
              - path: /dev/sdb
                wipe: true
        - name: microcloud03
          ovn_uplink_interface: ${var.bridge_nic}
          storage:
              local:
                path: /dev/sda
                wipe: true
              ceph:
              - path: /dev/sdb
                wipe: true
        - name: micro04
          ovn_uplink_interface: ${var.bridge_nic}
          storage:
              local:
                path: /dev/sda
                wipe: true
              ceph:
              - path: /dev/sdb
                wipe: true

        # `ceph` is optional and represents the Ceph global configuration
        ceph:
        internal_network: ${var.bridge_nic_cidr}
        public_network: ${var.bridge_nic_cidr}

        # `ovn` is optional and represents the OVN & uplink network configuration for LXD.
        ovn:
        ipv4_gateway: ${var.ovn_gateway}
        ipv4_range: ${var.ovn_range_start}-${var.ovn_range_end}
        dns_servers: 8.8.8.8

        # `storage` is optional and is used as basic filtering logic for finding disks across all systems.
        # Filters are checked in order of appearance.
        # The names and values of each key correspond to the YAML field names for the `api.ResouresStorageDisk`
        # struct here:
        # https://github.com/canonical/lxd/blob/c86603236167a43836c2766647e2fac97d79f899/shared/api/resource.go#L591
        # Supported operands: &&, ||, <, >, <=, >=, ==, !=, !
        # String values must not be in quotes unless the string contains a space.
        # Single quotes are fine, but double quotes must be escaped.
        # `find_min` and `find_max` can be used to validate the number of disks each filter finds.
        # `cephfs: true` can be used to optionally set up a CephFS file system alongside Ceph distributed storage.
        storage:
        cephfs: true
        ceph:
            - find: size > 10GiB && size < 50GiB 
            find_min: 1
            find_max: 2
            wipe: true
            - find: size > 10GiB && size < 50GiB && type == hdd && partitioned == false && block_size == 512
            find_min: 3
            find_max: 8
            wipe: false
    path: /home/ubuntu/microcloud.yaml
    owner: ubuntu:ubuntu
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
      size = "100GiB"
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
