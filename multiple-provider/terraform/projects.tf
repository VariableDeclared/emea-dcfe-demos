terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.52.0"
    }
  }
}

# Cloud Admin provider
provider "openstack" {
  user_name = var.cloud_admin_name
  password  = var.cloud_admin_password


  tenant_name = var.cloud_admin_project
  domain_name = var.cloud_admin_domain


  auth_url    = var.auth_url
  region      = var.region
  cacert_file = var.cacert
  insecure    = var.insecure
}

resource "openstack_identity_project_v3" "sp_domain" {
  name        = "service-provider"
  description = "Service Provider Domain"
  is_domain   = true
}

// Add project for COS, Add project for juju

resource "openstack_identity_project_v3" "cos_tenant" {
  name        = "cos-customer-0"
  description = "Tenant for the Canonical Observability Stack"
  domain_id   = openstack_identity_project_v3.sp_domain.id
}

resource "openstack_identity_project_v3" "juju_tenant" {
  name        = "juju-customer-0"
  description = "Tenant for the Canonical Observability Stack"
  domain_id   = openstack_identity_project_v3.sp_domain.id
}

resource "openstack_identity_project_v3" "k8s_tenant" {
  name        = "k8s-customer-0"
  description = "Tenant for Charmed Kubernetes"
  domain_id   = openstack_identity_project_v3.sp_domain.id
}
# Setup juju quotas

resource "openstack_networking_quota_v2" "development-project-quota" {
  project_id          = openstack_identity_project_v3.juju_tenant.id
  floatingip          = 3
  network             = 1
  port                = 100
  rbac_policy         = 10
  router              = 4
  security_group      = 200
  security_group_rule = 300
  subnet              = 8
  subnetpool          = 2
}

# Users


resource "openstack_identity_user_v3" "k8s_tenant_usr" {
  domain_id                             = openstack_identity_project_v3.sp_domain.id
  default_project_id                    = openstack_identity_project_v3.k8s_tenant.id
  name                                  = "k8s-tenant-usr"
  password                              = "k8s-tenant-usr"
  ignore_change_password_upon_first_use = true
  multi_factor_auth_enabled             = false
}


# Groups


resource "openstack_identity_group_v3" "domain_admins_group" {
  name        = "K8S Domain Admins"
  description = "K8S Domain Admins group"
  domain_id   = openstack_identity_project_v3.sp_domain.id
}


# User memberships


resource "openstack_identity_user_membership_v3" "k8s_tenant_usr" {
  user_id  = openstack_identity_user_v3.k8s_tenant_usr.id
  group_id = openstack_identity_group_v3.domain_admins_group.id
}



# Roles


data "openstack_identity_role_v3" "admin_role" {
  name = "Admin"
}


data "openstack_identity_role_v3" "member_role" {
  name = "member"
}


data "openstack_identity_role_v3" "reader_role" {
  name = "reader"
}


data "openstack_identity_role_v3" "load_balancer_admin_role" {
  name = "load-balancer_admin"
}




# Role assignments
resource "openstack_identity_role_assignment_v3" "engineering_domain_admins_admin" {
  domain_id = openstack_identity_project_v3.sp_domain.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.admin_role.id
}


resource "openstack_identity_role_assignment_v3" "k8s_t_admin" {
  project_id = openstack_identity_project_v3.k8s_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.admin_role.id
}

resource "openstack_identity_role_assignment_v3" "k8s_t_admin_lb" {
  project_id = openstack_identity_project_v3.k8s_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.load_balancer_admin_role.id
}


resource "openstack_identity_role_assignment_v3" "cos_t_admin" {
  project_id = openstack_identity_project_v3.cos_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.admin_role.id
}

resource "openstack_identity_role_assignment_v3" "cos_t_admin_lb" {
  project_id = openstack_identity_project_v3.cos_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.load_balancer_admin_role.id
}

resource "openstack_identity_role_assignment_v3" "juju_t_admin" {
  project_id = openstack_identity_project_v3.juju_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.admin_role.id
}

resource "openstack_identity_role_assignment_v3" "juju_t_admin_lb" {
  project_id = openstack_identity_project_v3.juju_tenant.id
  group_id  = openstack_identity_group_v3.domain_admins_group.id
  role_id   = data.openstack_identity_role_v3.load_balancer_admin_role.id
}
# Project networks


resource "openstack_networking_network_v2" "k8s_t_net" {
  name           = "k8s-net-0"
  admin_state_up = "true"
  tenant_id      = openstack_identity_project_v3.k8s_tenant.id
}


resource "openstack_networking_subnet_v2" "k8s_t_subnet" {
  network_id = openstack_networking_network_v2.k8s_t_net.id
  name       = "k8s-subnet-0"
  cidr       = "172.18.1.0/24"
  allocation_pool {
    start = "172.18.1.10"
    end   = "172.18.1.254"
  }
  tenant_id = openstack_identity_project_v3.k8s_tenant.id
}


resource "openstack_networking_network_v2" "juju_t_net" {
  name           = "juju-net-0"
  admin_state_up = "true"
  tenant_id      = openstack_identity_project_v3.juju_tenant.id
}

data "openstack_identity_project_v3" "admin_tenant" {
  name = "admin"
}

data "openstack_networking_network_v2" "provider_net" {
  name           = "ext-net"
  tenant_id      = data.openstack_identity_project_v3.admin_tenant.id
}




resource "openstack_networking_subnet_v2" "juju_t_subnet" {
  network_id = openstack_networking_network_v2.juju_t_net.id
  name       = "juju-subnet-0"
  cidr       = "172.18.1.0/24"
  allocation_pool {
    start = "172.18.1.10"
    end   = "172.18.1.254"
  }
  tenant_id = openstack_identity_project_v3.juju_tenant.id
}

resource "openstack_networking_network_v2" "cos_t_net" {
  name           = "cos-net-0"
  admin_state_up = "true"
  tenant_id      = openstack_identity_project_v3.cos_tenant.id
}


resource "openstack_networking_subnet_v2" "cos_t_subnet" {
  network_id = openstack_networking_network_v2.cos_t_net.id
  name       = "cos-subnet-0"
  cidr       = "172.18.1.0/24"
  allocation_pool {
    start = "172.18.1.10"
    end   = "172.18.1.254"
  }
  tenant_id = openstack_identity_project_v3.juju_tenant.id
}

# resource "openstack_networking_subnet_route_v2" "frontend-subnet-route" {
#   subnet_id        = openstack_networking_subnet_v2.frontend-subnet.id
#   destination_cidr = "192.168.20.0/24"
#   next_hop         = "192.168.10.2"
# }


# Internal router


resource "openstack_networking_router_v2" "k8s_t_router" {
  name                = "k8s-net-r0"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.provider_net.id
  tenant_id           = openstack_identity_project_v3.k8s_tenant.id
}



resource "openstack_networking_router_interface_v2" "k8s_t_router_tiface" {
  router_id = openstack_networking_router_v2.k8s_t_router.id
  subnet_id = openstack_networking_subnet_v2.k8s_t_subnet.id
}


# Internal router


resource "openstack_networking_router_v2" "juju_t_router" {
  name                = "juju-net-r0"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.provider_net.id
  tenant_id           = openstack_identity_project_v3.juju_tenant.id
}



resource "openstack_networking_router_interface_v2" "juju_t_router_tiface" {
  router_id = openstack_networking_router_v2.juju_t_router.id
  subnet_id = openstack_networking_subnet_v2.juju_t_subnet.id
}

# Internal router


resource "openstack_networking_router_v2" "cos_t_router" {
  name                = "cos-net-r0"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.provider_net.id
  tenant_id           = openstack_identity_project_v3.cos_tenant.id
}



resource "openstack_networking_router_interface_v2" "cos_t_router_tiface" {
  router_id = openstack_networking_router_v2.cos_t_router.id
  subnet_id = openstack_networking_subnet_v2.cos_t_subnet.id
}

# Security groups


resource "openstack_networking_secgroup_v2" "cos_jumphost_servers_secgroup" {
  name        = "Jumphost servers"
  description = "Security group allowing traffic to Jumphost servers"
  tenant_id   = openstack_identity_project_v3.cos_tenant.id
}

resource "openstack_networking_secgroup_v2" "k8s_jumphost_servers_secgroup" {
  name        = "Jumphost servers"
  description = "Security group allowing traffic to Jumphost servers"
  tenant_id   = openstack_identity_project_v3.k8s_tenant.id
}

resource "openstack_networking_secgroup_v2" "juju_jumphost_servers_secgroup" {
  name        = "Jumphost servers"
  description = "Security group allowing traffic to Jumphost servers"
  tenant_id   = openstack_identity_project_v3.juju_tenant.id
}



# Security group rules


resource "openstack_networking_secgroup_rule_v2" "k8s_jumphost_servers_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.k8s_jumphost_servers_secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "cos_jumphost_servers_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.cos_jumphost_servers_secgroup.id
}


resource "openstack_networking_secgroup_rule_v2" "juju_jumphost_servers_secgroup_rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.juju_jumphost_servers_secgroup.id
}

