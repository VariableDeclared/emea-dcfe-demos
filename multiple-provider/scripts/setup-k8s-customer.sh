#!/bin/bash

WHAT=k8s
TENANT_PROJECT=${WHAT}-customer-0
KUBERNETES_TENANT_NETWORK=${WHAT}-net-0
KUBERNETES_TENANT_SUBNET=${WHAT}-subnet-0
KUBERNETES_TENANT_ROUTER=${WHAT}-net-r0
STARTING_OCTETS=172.18.1
SUBNET_RANGE=${STARTING_OCTETS}.0/24


openstack project create ${TENANT_PROJECT} --domain admin_domain
openstack network create --project ${TENANT_PROJECT} ${KUBERNETES_TENANT_NETWORK}
openstack subnet create --dhcp --dns-nameserver 172.27.60.1 --project ${TENANT_PROJECT} --network ${KUBERNETES_TENANT_NETWORK} --subnet-range ${SUBNET_RANGE} ${KUBERNETES_TENANT_SUBNET}
openstack router create --project ${TENANT_PROJECT} ${KUBERNETES_TENANT_ROUTER}
openstack port create --network ${KUBERNETES_TENANT_NETWORK} --project ${TENANT_PROJECT} --fixed-ip subnet=${KUBERNETES_TENANT_SUBNET},ip-address=${STARTING_OCTETS}.1 ${WHAT}-port-internal
openstack router add port ${KUBERNETES_TENANT_ROUTER} ${WHAT}-port-internal
openstack router set --external-gateway ext-net ${KUBERNETES_TENANT_ROUTER}
# vi ~/.local/share/juju/credentials.yaml
# source ~/openstack-on-orangebox/yoga/generated/openstack/novarc
# openstack project list
openstack role add --user admin --project ${TENANT_PROJECT} load-balancer_admin
openstack role add --user admin --project ${TENANT_PROJECT} Admin
juju add-model ${WHAT} --credential k8s-customer-1 --config="network=${KUBERNETES_TENANT_NETWORK}" --config="external-network=ext-net" openstack_cloud/RegionOne


