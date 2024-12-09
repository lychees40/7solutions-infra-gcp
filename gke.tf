// GKE Cluster
module "gke" {
  source            = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster-update-variant"
  version           = "34.0.0"
  project_id        = var.project_id
  name              = "${var.name}-${var.env}-gke"
  region            = var.region
  zones             = ["${var.region}-a"]
  network           = module.vpc.network_name
  subnetwork        = module.vpc.subnets_names[0]
  ip_range_pods     = "gke-pods"
  ip_range_services = "gke-services"

  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = true

  enable_private_nodes              = true
  master_ipv4_cidr_block            = var.gke_master_ipv4_cidr_block
  dns_cache                         = false
  add_cluster_firewall_rules        = true
  add_master_webhook_firewall_rules = true
  add_shadow_firewall_rules         = true
  deletion_protection               = false

  remove_default_node_pool          = true
  disable_legacy_metadata_endpoints = true
  network_policy                    = true

  gateway_api_channel                 = "CHANNEL_STANDARD"
  security_posture_mode               = "BASIC"
  security_posture_vulnerability_mode = "VULNERABILITY_BASIC"
  release_channel                     = "STABLE"
  kubernetes_version                  = "1.30.5-gke.1443001"

  monitoring_enable_managed_prometheus = true
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS"]
  monitoring_service                   = "monitoring.googleapis.com/kubernetes"

  logging_enabled_components = ["SYSTEM_COMPONENTS"]
  logging_service            = "logging.googleapis.com/kubernetes"


  # enable_secret_manager_addon = true
  # workload_vulnerability_mode = "BASIC"
  # workload_config_audit_mode  = "BASIC"
  # enable_intranode_visibility = true

  # }
  // Open gke control plane API conditionally
  enable_private_endpoint = var.control_plane_open ? false : true
  master_authorized_networks = var.control_plane_open ? [
    {
      # cidr_block   = "${chomp(data.http.ip_checker.body)}/32"
      cidr_block   = "0.0.0.0/0"
      display_name = "terraform-runner"
    }
  ] : []
  depends_on = [module.vpc]

  node_pools = [
    {
      name = "${var.name}${var.env}-node-pool"
      # Default quotas for GKE = 8 core per region
      machine_type         = "e2-standard-2"
      node_locations       = "${var.region}-a"
      min_count            = 1
      max_count            = 6
      disk_size_gb         = 50
      disk_type            = "pd-ssd"
      kubernetes_version   = "1.30.5-gke.1443001"
      auto_repair          = true
      auto_upgrade         = true
      preemptible          = false
      initial_node_count   = 1
      enable_private_nodes = true
      logging_variant      = "DEFAULT"
      strategy             = "BLUE_GREEN"
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  cluster_resource_labels = {
    env     = var.env
    project = var.project_id
  }
}
