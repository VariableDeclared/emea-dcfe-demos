#cloud-config
network:
  version: 2
  ethernets:
      eth0:
          dhcp4: true
      eth1:
          dhcp4: false
          addresses: [${switch_network_sw1}.${node_final_octet}/24]
          routes:
          - to: default
            via: ${switch_network_sw1}.${switch_final_octet}
      eth2:
          dhcp4: false
          addresses: [${switch_network_sw2}.${node_final_octet}/24]
