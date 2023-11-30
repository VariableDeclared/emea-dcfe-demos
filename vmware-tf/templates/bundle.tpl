applications:
  etcd:
    charm: etcd
    num_units: 1
    bindings:
      "": bgp
    to:
    - 0
  easyrsa:
    charm: easyrsa
    num_units: 1
    bindings:
      "": bgp
    to:
    - 0
  kubernetes-control-plane:
    charm: kubernetes-control-plane
    num_units: 2
    channel: 1.28/stable
    options:
      allow-privileged: "true"
    bindings:
      "": bgp
    to:
    - 1
    - 0
  kubernetes-worker:
    charm: kubernetes-worker
    channel: 1.28/stable
    num_units: 3
    bindings:
      "": bgp
    to:
    - 2
    - 3
    - 4
  containerd:
    charm: containerd
    bindings:
      "": bgp
  tigera:
    charm: {CHARM_PATH}
    resources:
      calico-crd-manifest: {TIGERA_CRD_MANIFEST}
      calico-enterprise-manifest: {TIGERA_DEPLOYMENT_MANIFEST}
    options:
      stable_ip_cidr: 10.30.30.0/24
      nic_autodetection_cidrs: "10.10.10.0/24,10.10.20.0/24"
      image_registry_secret: "{TIGERA_REGISTRY_USER}:{TIGERA_REGISTRY_PASSWORD}"
      license: include-base64:///{TIGERA_LICENSE_FILE_PATH}
      bgp_parameters: | %{ for node in nodes }
        - hostname: ${node.hostname}
          asn: ${node.stableIPASN}
          stableAddress: ${node.stableIP}
          rack: ${node.rackName}
          interfaces:
          - IP: ${node.sw1Interface}
            peerIP: ${node.sw1IP}
            peerASN: ${node.sw1ASN}
          - IP: ${node.sw2Interface}
            peerIP: ${node.sw2IP}
            peerASN: ${node.sw2ASN} %{~ endfor }
    bindings:
      "": bgp
machines: %{ for i in range(0, length(nodes)) }
  "${i}": %{~ endfor }
relations:
- - kubernetes-worker:cni
  - tigera
- - kubernetes-control-plane:cni
  - tigera
- - kubernetes-control-plane:kube-control
  - kubernetes-worker
- - easyrsa
  - etcd
- - easyrsa
  - kubernetes-control-plane
- - easyrsa
  - kubernetes-worker
- - kubernetes-control-plane
  - etcd
- - kubernetes-control-plane
  - containerd
- - kubernetes-worker
  - containerd