#cloud-config
network:
  version: 2
  ethernets:
      eth0:
          dhcp4: true
      eth1:
          dhcp4: false
          addresses: [${switch_network}.${switch_final_octet}/24]
