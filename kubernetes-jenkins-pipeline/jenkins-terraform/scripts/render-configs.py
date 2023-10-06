#!/bin/env python3
import argparse
import yaml


O7K_CLOUD_CONFIG = {
    "clouds": {
        "openstack_cloud": {
            "type": "openstack",
            "auth-types": [
                "access-key",
                "userpass"
            ],
            "regions": {
                "RegionOne": {
                    "endpoint": ""
                }
            },
            "ca-certificates": []
        }
    }
}

parser = argparse.ArgumentParser()
parser.add_argument("ca", help="path to the Openstack CA certificate")
parser.add_argument("keystone_url", help="keystone URL")
parser.add_argument("--dest", default="openstack-cloud.yaml", required=False)

def render_configs(args):
    O7K_CLOUD_CONFIG["clouds"]["openstack_cloud"]["regions"]["RegionOne"].update({
        "endpoint": args.keystone_url
    })
    ca_cert_content = None
    with open(args.ca, 'r') as fh:
        ca_cert_content = fh.read()

    O7K_CLOUD_CONFIG["clouds"]["openstack_cloud"]["ca-certificates"] = [ca_cert_content]
    
    with open(args.dest, 'w') as fh:
        fh.write(yaml.safe_dump(O7K_CLOUD_CONFIG))

    print("Rendered cloud config")

if __name__ == "__main__":
    args = parser.parse_args()
    render_configs(args)