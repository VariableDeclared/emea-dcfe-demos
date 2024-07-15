
variable "pro_token" {
    type = string
}


variable "bridge_nic" {
    type = string
    default = "br0"
}


variable "ovn_gateway" {
    type = string
    default = "10.10.32.1"
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