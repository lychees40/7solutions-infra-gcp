data "google_client_config" "default" {
}

data "google_dns_managed_zone" "dns_zone" {
  name    = var.cloud_dns_zone_name
  project = var.project_id
}

data "http" "ip_checker" {
  url = "http://icanhazip.com"
}
