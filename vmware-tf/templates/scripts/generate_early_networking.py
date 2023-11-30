import ipaddress
import yaml
import jinja2


NODE_TEMPLATE = """
interfaceAddresses:
      - 10.246.153.{{final_octet}}
      - 10.246.153.{{final_octet}}
stableAddress:
    address: 10.30.30.${{final_octet}}
asNumber: {{65000+final_octet}}
peerings:
    - peerIP: {{tor1_ip}}
      peerASNumber: {{tor_sw1_asn}}
    - peerIP: {{tor2_ip}}
      peerASNumber: {{tor_sw2_asn}}
labels:
    rack: rack1
"""
TOR1_CIDR = "10.246.155.0/24"
TOR2_CIDR = "10.246.156.0/24"


def generate_early_config():
    tor1_cidr = ipaddress.IPv4Network(TOR1_CIDR)
    tor2_cidr = ipaddress.IPv4Network(TOR2_CIDR)
    nodes_template = jinja2.Template(NODE_TEMPLATE)

    early_network_config = {
        "apiVersion": "projectcalico.org/v3",
        "kind": "EarlyNetworkingConfiguration",
        "spec": {
            "nodes": [
                yaml.safe_load(
                    nodes_template.render(
                        **{
                            "final_octet": ip,
                            "tor1_ip": "10.246.153.1",
                            "tor2_ip": "10.246.154.1",
                            "tor_sw1_asn": 65501,
                            "tor_sw2_asn": 65502,
                        }
                    )
                )
                for ip in range(0, 254)
            ]
        },
    }
    with open("./template.rendered.yaml", "w") as fh:
        fh.write(yaml.safe_dump(early_network_config, indent=1))


generate_early_config()
