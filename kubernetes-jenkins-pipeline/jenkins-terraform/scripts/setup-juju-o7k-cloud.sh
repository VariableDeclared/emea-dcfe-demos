#!/bin/bash

O7K_KEYSTONE_URL=$1
O7K_CA_CERT=$2
OS_PASSWD=$3
OS_DOMAIN_NAME=$4
OS_TENANT_NAME=$5
OS_USERNAME=$6


cat <<END > ./micro-ck8s.yaml
series: jammy
applications:
  easyrsa:
    charm: easyrsa
    channel: stable
    num_units: 1
    to:
    - "0"
    constraints: arch=amd64
  etcd:
    charm: etcd
    channel: stable
    num_units: 1
    to:
    - "0"
    constraints: arch=amd64
  kubernetes-control-plane:
    charm: kubernetes-control-plane
    channel: 1.28/stable
    num_units: 1
    options:
      allow-privileged: "true"
    to:
    - "0"
    constraints: arch=amd64
  calico:
    charm: calico
    channel: stable
  containerd:
    charm: containerd
    channel: stable
  kubernetes-worker:
    charm: kubernetes-worker
    channel: 1.28/stable
    num_units: 2
    to:
    - "1"
    - "2"
    constraints: arch=amd64
machines:
  "0":
    constraints: cores=2 mem=4G root-disk=20G root-disk-source=volume allocate-public-ip=true
    # machine: availability-zone=az-3
  "1":
    constraints: cores=2 mem=4G root-disk=20G root-disk-source=volume allocate-public-ip=true
    # machine: availability-zone=az-2
  "2":
    constraints: cores=2 mem=4G root-disk=20G root-disk-source=volume allocate-public-ip=true
    # machine: availability-zone=az-1
relations:
- - easyrsa:client
  - etcd:certificates
- - easyrsa:client
  - kubernetes-control-plane:certificates
- - easyrsa:client
  - kubernetes-worker:certificates
- - etcd:db
  - kubernetes-control-plane:etcd
- - kubernetes-control-plane:kube-control
  - kubernetes-worker:kube-control
- - calico
  - kubernetes-control-plane
- - calico
  - etcd
- - calico
  - kubernetes-worker
- - containerd
  - kubernetes-control-plane
- - containerd
  - kubernetes-worker

END

cat <<END > ./openstack-credential.yaml
credentials:
   openstack_cloud:
      alice-credential:
        auth-type: userpass
        domain-name: ""
        password: "$OS_PASSWD"
        project-domain-name: "$OS_DOMAIN_NAME"
        tenant-name: "$OS_TENANT_NAME"
        user-domain-name: "$OS_DOMAIN_NAME"
        username: "$OS_USERNAME"
END

./render-configs.py $O7K_CA_CERT $O7K_KEYSTONE_URL

juju add-cloud --client -f openstack-cloud.yaml || true
juju add-credential openstack_cloud --client -f openstack-credential.yaml || true
