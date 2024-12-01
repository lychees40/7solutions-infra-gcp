variable "project_id" {
  description = "The Google Cloud project ID where resources will be deployed."
  type        = string
}

variable "name" {
  description = "The name identifier for the GKE cluster."
  type        = string
}

variable "env" {
  description = "The environment identifier for the deployment, such as 'production', 'staging', or 'development'."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where resources will be deployed, e.g., 'asia-southeast1'."
  type        = string
}

variable "subnet_cidr" {
  description = "The CIDR block range for the primary subnet within the VPC."
  type        = string
}

variable "secondary_ranges_gke_pods" {
  description = "The CIDR block range for the secondary subnet dedicated to GKE pods."
  type        = string
}

variable "secondary_ranges_gke_services" {
  description = "The CIDR block range for the secondary subnet dedicated to GKE services."
  type        = string
}

variable "gke_master_ipv4_cidr_block" {
  description = "The CIDR block reserved for the GKE master (control plane) nodes."
  type        = string
}

variable "domain" {
  description = "The primary domain name used for accessing services deployed in the cluster, e.g., 'nonprod.chxwe.com'."
  type        = string
}

variable "cloud_dns_zone_name" {
  description = "The name of the Cloud DNS zone managing the specified domain."
  type        = string
}

variable "control_plane_open" {
  description = "Flag to enable (`true`) or disable (`false`) access to the GKE control plane API."
  type        = bool
}
