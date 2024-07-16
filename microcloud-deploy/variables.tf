
variable "pro_token" {
    type = string
}

variable "lxd_project" {
    type = string
    default = "microcloud2"
}
variable "bridge_nic" {
    type = string
    default = "enp5s0"
}
variable "lookup_subnet" {
    type = string
    default = "10.10.32.0/24"
}

variable "ovn_gateway" {
    type = string
    default = "10.10.32.1/24"
}
variable "ovn_range_start" {
    type = string
    default = "10.10.32.150"
}
variable "ovn_range_end" {
    type = string
    default = "10.10.32.200"
}
variable "ssh_pubkey" {
    type = string
}
variable "bridge_nic_cidr" {
    type = string
}