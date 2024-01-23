#!/bin/bash

juju exec --application microk8s -- " if ! grep -q 'cloud-provider=external' /var/snap/microk8s/current/args/kubelet; then sudo echo '--cloud-provider=external' >> /var/snap/microk8s/current/args/kubelet; fi "
juju exec --application microk8s -- " if ! grep -q 'cloud-provider=external' /var/snap/microk8s/current/args/kube-controller-manager ; then sudo echo '--cloud-provider=external' >> /var/snap/microk8s/current/args/kube-controller-manager; fi "
juju exec -a microk8s -- sudo snap refresh --hold microk8s
juju exec -a microk8s -- "sudo snap restart microk8s"
juju scp -m foundation-openstack:cos /home/ubuntu/openstack-on-orangebox/yoga/ssl/rootCA.crt 0:/home/ubuntu/certs/openstack-ca.crt
juju ssh -m foundation-openstack:cos 0 -- mkdir -p /home/ubuntu/certs
juju ssh -m foundation-openstack:cos 0 -- sudo cp /home/ubuntu/certs/openstack-ca.crt /etc/openstack/certs/openstack-ca.crt
# juju exec --application microk8s "microk8s config" > ~/.kube/config
