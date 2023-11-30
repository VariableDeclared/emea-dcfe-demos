#!/bin/env python3
import jinja2
import json
import argparse
import subprocess

parser = argparse.ArgumentParser("Calico Early Renderer")

def render_calico_early(args):
    calico_early_template = None

    with open("/tmp/calico_early.tpl", "r") as fh:
        calico_early_template = jinja2.Template(fh.read())

    ip_json = json.loads(subprocess.check_output("ip -j -4 a".split()).decode("utf-8"))
    ip_ens192 = [[ip["addr_info"][0]["local"] for ip in ip_json if ip["ifname"] == "ens192"][0]][0]
    ip_ens224 = [[ip["addr_info"][0]["local"] for ip in ip_json if ip["ifname"] == "ens224"][0]][0]
    hostname = json.loads(subprocess.check_output("hostnamectl status --json short".split()).decode("utf-8"))['StaticHostname']
    node_info = {
        f"node{hostname.split('-')[2]}_interface1_addr": ip_ens192,
        f"node{hostname.split('-')[2]}_interface2_addr": ip_ens224,
    }

    with open("/calico-early/cfg.yaml", "w") as fh:
        fh.write(calico_early_template.render(**node_info))

    print("Rendered calico early")

if __name__ == "__main__":
    args = parser.parse_args()
    render_calico_early(args)
