# Username of Cloud Admin, optional. Defaults to "admin"
# cloud_admin_name = "admin"


# Cloud Admin's password, mandatory
cloud_admin_password = "admin"


# Default project for Cloud Admin, optional. Defaults to "admin"
# cloud_admin_project = "admin"


# Domain name for Cloud Admin, optional. Defaults to "admin_domain"
# cloud_admin_domain = "admin_domain"


# Keystone endpoint URL, mandatory
auth_url = "https://keystone.orange.box:5000/v3"


# OpenStack region name, optional. Defaults to "RegionOne"
# region = "RegionOne"


# CA certificate to connect to Keystone endpoint URL, optional
# cacert = "cacert.pem"


# Trust self-signed SSL certificates, optional. Defaults to "true"
# insecure = true


# Path to a demo SSH key. User “Alice” will get this key uploaded in Openstack
# You can use “${path.module}” to refer to the current terraform directory
ssh_key_path = "./id_rsa.pub"

