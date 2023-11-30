variable "vsphere_user" {
    type = string
    default = "USER NOT SET"
}

variable "vsphere_password" {
    type = string
    default = "PASSWORD NOT SET" 
}

variable "vsphere_server" {
    type = string
    default = "http://127.0.0.1"
}

variable "tigera_registry_user" {
    type = string
    default = "VALUE NOT SET"
}

variable "tigera_registry_password" {
    type = string
    default = "VALUE NOT SET"
}

variable "calico_early_version" {
    type = string
    default = "3.17.1"
}