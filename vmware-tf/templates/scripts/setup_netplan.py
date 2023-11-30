#!/bin/env python3
import yaml
import subprocess
import json


def reconfigure_netplan():
    netplan = None
    subprocess.check_call("sudo dhclient".split())

    with open('/etc/netplan/50-cloud-init.yaml', 'r') as fh:
        netplan = yaml.safe_load(fh.read())
    ip_json = json.loads(subprocess.check_output("ip -j -4 a".split()).decode('utf-8'))
    netplan['network']['ethernets'].update({
            "ens192": {
                "routes": [{
                    "to": "default",
                    "via": "10.246.154.134"
                }],
                "addresses": [[ip['addr_info'][0]['local'] for ip in ip_json if ip['ifname'] == "ens192"][0] + "/24"]
            },
            "ens224": {
                "routes": [{
                    "to": "0.0.0.0/1",
                    "via": "10.246.155.36"
                }],
                "addresses": [[ip['addr_info'][0]['local'] for ip in ip_json if ip['ifname'] == "ens224"][0] + "/24"]
            }
        })
    with open('/etc/netplan/50-cloud-init.yaml', 'w') as fh:
        fh.write(yaml.dump(netplan))
    print("Wrote updated netplan!")

    subprocess.call("sudo netplan apply".split())

if __name__ == "__main__":
    reconfigure_netplan()