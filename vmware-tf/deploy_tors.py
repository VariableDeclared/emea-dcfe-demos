#!/bin/env python3
import argparse
import subprocess
import pathlib
import json
import jinja2
import tempfile

parser = argparse.ArgumentParser("Dual ToR Script for VMWare")

def _cli(cmd, return_output=False):
    if return_output:
        return subprocess.check_output(cmd.split(" ").decode('utf-8'))

    return subprocess.call(cmd.split(" "))

def deploy_tors():
    cloud_init_template = jinja2.Template(open("./templates/tor-cloud-init.jinja2", "r").read())
    # TODO: ToR jinja args
    template_args = {}
    cloud_init_tmp = tempfile.TemporaryFile('w')
    cloud_init_tmp.write(cloud_init_template.render(kwargs=template_args))
    cloud_init_tmp.flush()
    _cli(f"juju add-model dual-tor --model-config {cloud_init_tmp.read()}")
    _cli(f"juju deploy ubuntu -n 1")



def configure_and_deploy_k8s():
    machines = json.loads(_cli("juju machines --format json"), True)
    ips = list(filter(lambda machine: machine['juju-status']['ip-addresses'][0], machines))
    # TODO: K8s bundle
    k8s_bundle_template = jinja2.Template(open("./templates/k8s-bundle.jinja2", "r").read())
    cloud_init = pathlib.Path(f"{__path__}/k8s-cloud-init.yaml")
    # TODO: Add dict for the template
    k8s_args = {}

    with open(cloud_init, 'w') as fh:
        fh.write(k8s_bundle_template.render(kwargs=k8s_args))

    

    
    

def main():
    pass