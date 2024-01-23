variable "cloud_admin_name" {
  description = "Username of Cloud Admin"
  default     = "admin"
}

variable "cloud_admin_password" {
  description = "Cloud Admin's password"
}

variable "cloud_admin_project" {
  description = "Cloud Admin's Project"
}


variable "cloud_admin_domain" {
  description = "Domain name for Cloud Admin"
  default     = "admin_domain"
}


variable "auth_url" {
  description = "Keystone endpoint URL"
}

variable "region" {
  description = "OpenStack region name"
  default     = "RegionOne"
}


variable "cacert" {
  description = "CA certificate to connect to Keystone endpoint URL"
  default     = ""
}


variable "insecure" {
  description = "Trust self-signed SSL certificates"
  default     = true
}