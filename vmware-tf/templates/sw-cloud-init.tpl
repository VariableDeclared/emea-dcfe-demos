#cloud-config
package_update: true
package_upgrade: true
packages:
- bird2
users:
  - name: ubuntu
    ssh_import_id:
    - lp:pjds
    groups: [adm, audio, cdrom, dialout, floppy, video, plugdev, dip, netdev]
    plain_text_passwd: "ubuntu"
    shell: /bin/bash
    lock_passwd: false
    sudo:
    - ALL=(ALL) NOPASSWD:ALL
write_files:
- content: |
    filter packet_bgp {
      # the IP range(s) to announce via BGP from this machine
      # these IP addresses need to be bound to the lo interface
      # to be reachable; the default behavior is to accept all
      # prefixes bound to interface lo
      if net = 10.30.30.0/24 then accept;
      reject;

    }


    router id ${stable_ip};
    # listen bgp;
    debug protocols all;


    protocol direct {
      interface "lo"; # Restrict network interfaces BIRD works with
    }


    protocol kernel {
      persist on; # Don't remove routes on bird shutdown
      # scan time 20; # Scan kernel routing table every 20 seconds
      ipv4 {
          import all; # Default is import all
          export all; # Default is export none
      };
    }


    # This pseudo-protocol watches all interface up/down events.
    protocol device {
      scan time 10; # Scan interfaces every 10 seconds
    }


    protocol bgp neighbor_v4_${switch} {
      local as ${switch_asn};
      allow local as ${switch_asn};
      neighbor range ${switch_network}.0/24 external; # IP from the virtual switch

      ipv4 {
          export filter packet_bgp;
          import all;
      };

      direct;
    }


  path: /etc/bird/bird.conf
  owner: root:root

runcmd:
- [sysctl, -w, net.ipv4.ip_forward=1]
- [apt, update]
- [DEBIAN_FRONTEND=noninteractive, apt, install, -y, bird2]
- [systemctl, restart, bird]
- [ip, a, add, dev, lo, brd, +, ${stable_ip}]
# TODO:
# - ['iptables', '-t', 'nat', '-A', 'POSTROUTING', '-o', 'eth0', '-j', 'SNAT', '--to', 'TODO']