
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "9.3.0"

  project_id   = var.project_id
  network_name = "${var.name}-${var.env}-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name = "${var.name}-${var.env}-subnet-01"
      subnet_ip   = var.subnet_cidr

      subnet_region    = var.region
      subnet_flow_logs = "true"
    }
  ]

  secondary_ranges = {
    "${var.name}-${var.env}-subnet-01" = [
      {
        range_name    = "gke-pods"
        ip_cidr_range = var.secondary_ranges_gke_pods
      },
      {
        range_name    = "gke-services"
        ip_cidr_range = var.secondary_ranges_gke_services
      }
    ]
  }

  ingress_rules = [
    {
      name          = "allow-https"
      description   = "Allow https from anywhere"
      direction     = "INGRESS"
      priority      = 1000
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["443"]
        }
      ]
    },
    {
      name          = "allow-http"
      description   = "Allow http from anywhere"
      direction     = "INGRESS"
      priority      = 1001
      source_ranges = ["0.0.0.0/0"]
      allow = [
        {
          protocol = "tcp"
          ports    = ["80"]
        }
      ]
    }
  ]
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "5.3.0"
  project_id = var.project_id
  region     = var.region
  router     = google_compute_router.router.name
  name       = "${var.name}-${var.env}-nat-config"
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.name}-${var.env}-nat-router"
  network = module.vpc.network_name
  region  = var.region
}


// Preparing argocd IP address and DNS record
resource "google_compute_global_address" "static" {
  name       = "argocd-ipv4"
  project    = var.project_id
  depends_on = [module.gke]
}

resource "google_dns_record_set" "dns" {
  name         = "argocd.${var.domain}."
  type         = "A"
  ttl          = 300
  project      = var.project_id
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.static.address]
}
