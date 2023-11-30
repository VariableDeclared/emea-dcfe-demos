terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.3.1"
    }
  }
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "datacenter" {
  name = "Boston"
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Development"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# 10.246.153.0/24 
data "vsphere_network" "vlan_2763" {
  name          = "VLAN_2763"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
# 10.246.154.0/24 
data "vsphere_network" "vlan_2764" {
  name          = "VLAN_2764"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
# 10.246.155.0/24 
data "vsphere_network" "vlan_2765" {
  name          = "VLAN_2765"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = "vsanDatastore"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


data "vsphere_virtual_machine" "template" {
  name          = "ubuntu-jammy-larger-var"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "default" {
  name          = format("%s%s", data.vsphere_compute_cluster.cluster.name, "/Resources")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = "eyerok.internal"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_ovf_vm_template" "ubuntu_jammy" {
  name              = "ubuntu-ovf-deploy"
  disk_provisioning = "thin"
  resource_pool_id  = data.vsphere_resource_pool.default.id
  datastore_id      = data.vsphere_datastore.datastore.id
  host_system_id    = data.vsphere_host.host.id
  remote_ovf_url    = "http://cloud-images.ubuntu.com/daily/server/jammy/current/jammy-server-cloudimg-amd64.ova"
  ovf_network_map = {
    "VM Network" : data.vsphere_network.vlan_2764.id
  }
}

resource "vsphere_virtual_machine" "juju_nodes" {

  count                = 1
  name                 = "juju-test-${count.index}"
  datacenter_id        = data.vsphere_datacenter.datacenter.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  num_cpus             = 2
  num_cores_per_socket = 2
  memory               = 16384
  guest_id             = data.vsphere_ovf_vm_template.ubuntu_jammy.guest_id
  firmware             = data.vsphere_ovf_vm_template.ubuntu_jammy.firmware
  scsi_type            = data.vsphere_ovf_vm_template.ubuntu_jammy.scsi_type
  nested_hv_enabled    = data.vsphere_ovf_vm_template.ubuntu_jammy.nested_hv_enabled
  folder               = "fe-crew-root/pjds/manual-machines"
  vapp {
    properties = {
      hostname  = "juju-test-${count.index}"
    }
  }
  network_interface {
    network_id = data.vsphere_network.vlan_2764.id
  }
  network_interface {
    network_id = data.vsphere_network.vlan_2765.id
  }
  cdrom {
    client_device = true
  }
  ovf_deploy {
    allow_unverified_ssl_cert = false
    remote_ovf_url            = data.vsphere_ovf_vm_template.ubuntu_jammy.remote_ovf_url
    disk_provisioning         = data.vsphere_ovf_vm_template.ubuntu_jammy.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.ubuntu_jammy.ovf_network_map
  }
  disk {
    label       = "sda"
    size        = 100
    unit_number = 0
  }
}

# Cloud init example
# data "cloudinit_config" "calico_early" {
#   gzip          = false
#   base64_encode = true
#   part {
#     filename     = "cloud-config.yaml"
#     content_type = "text/cloud-config"
#     content = templatefile("${path.module}/templates/tigera-early-networking.tpl", {
#       tor_sw1_asn              = 65021,
#       tor_sw2_asn              = 65031,
#       tor_sw1_octet            = "3",
#       tor_sw2_octet            = "3",
#       switch_network_sw1       = vsphere_virtual_machine.tor1.default_ip_address,
#       switch_network_sw2       = vsphere_virtual_machine.tor2.default_ip_address,
#       mgmt_network             = "10.246.153",
#       node_final_octet         = 12
#       nodes                    = range(0, 5),
#       tigera_registry_user     = var.tigera_registry_user,
#       tigera_registry_password = var.tigera_registry_password,
#       calico_early_version     = var.calico_early_version,
#       k8s_prefix               = "k8s-node"
#     })
#   }
# }

resource "vsphere_virtual_machine" "k8s_nodes" {

  count                = 7
  name                 = "k8s-test-${count.index}"
  datacenter_id        = data.vsphere_datacenter.datacenter.id
  resource_pool_id     = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id         = data.vsphere_datastore.datastore.id
  host_system_id       = data.vsphere_host.host.id
  num_cpus             = 2
  num_cores_per_socket = 2
  memory               = 16384
  guest_id             = data.vsphere_ovf_vm_template.ubuntu_jammy.guest_id
  firmware             = data.vsphere_ovf_vm_template.ubuntu_jammy.firmware
  scsi_type            = data.vsphere_ovf_vm_template.ubuntu_jammy.scsi_type
  nested_hv_enabled    = data.vsphere_ovf_vm_template.ubuntu_jammy.nested_hv_enabled
  folder               = "fe-crew-root/pjds/manual-machines"
  vapp {
    properties = {
      hostname  = "k8s-node-${count.index}"
      # Cloud init example
      # user-data = data.cloudinit_config.calico_early.rendered
    }
  }
  network_interface {
    network_id = data.vsphere_network.vlan_2764.id
  }
  network_interface {
    network_id = data.vsphere_network.vlan_2765.id
  }
  cdrom {
    client_device = true
  }
  ovf_deploy {
    allow_unverified_ssl_cert = false
    remote_ovf_url            = data.vsphere_ovf_vm_template.ubuntu_jammy.remote_ovf_url
    disk_provisioning         = data.vsphere_ovf_vm_template.ubuntu_jammy.disk_provisioning
    ovf_network_map           = data.vsphere_ovf_vm_template.ubuntu_jammy.ovf_network_map
  }
  # Cloud init example
  # extra_config = {
  #   "guestinfo.metadata"          = data.cloudinit_config.calico_early.rendered
  #   "guestinfo.metadata.encoding" = "base64"
  #   "guestinfo.userdata"          = data.cloudinit_config.calico_early.rendered
  #   "guestinfo.userdata.encoding" = "base64"
  # }
  disk {
    label       = "sda"
    size        = 100
    unit_number = 0
  }

}
