# 7solutions-infra-gcp

## Overview

This project sets up the infrastructure for the 7 Solutions assignment, including networking and a GKE private cluster with Argo CD.

## Prerequisites

- **GCP Project ID**: The Google Cloud project where resources will be deployed.
- **GCP Service Account**: With appropriate permissions for resource creation.
- **GCP Service Account Key File**: JSON key file for the service account.
- **Public Domain Name**: A domain name you own with a valid Cloud DNS zone.
- **Cloud DNS Zone**: Configured in GCP for your domain.
- **GCP Bucket**: For Terraform state backend.

## Configuration Variables

The following Terraform variables are used to configure the infrastructure deployment:

| Variable                        | Description                                          | Type   |
| ------------------------------- | ---------------------------------------------------- | ------ |
| `project_id`                    | The project ID to deploy resources                   | string |
| `name`                          | The name of the GKE cluster                          | string |
| `env`                           | The environment name for the GKE cluster             | string |
| `region`                        | The region to deploy resources                       | string |
| `subnet_cidr`                   | The CIDR block for the subnet                        | string |
| `secondary_ranges_gke_pods`     | The CIDR block for the secondary subnet for pods     | string |
| `secondary_ranges_gke_services` | The CIDR block for the secondary subnet for services | string |
| `gke_master_ipv4_cidr_block`    | The CIDR block for the GKE master                    | string |
| `domain`                        | Domain name zone                                     | string |
| `cloud_dns_zone_name`           | Cloud DNS zone name                                  | string |
| `control_plane_open`            | Enable or disable the control plane API              | bool   |

### Example `terraform.tfvars` File

```hcl
# TF_Variables
project_id                    = "example-project"
name                          = "example"
env                           = "nonprod"
region                        = "asia-southeast1"
subnet_cidr                   = "10.0.0.0/16"
secondary_ranges_gke_pods     = "10.1.0.0/16"
secondary_ranges_gke_services = "10.2.0.0/24"
gke_master_ipv4_cidr_block    = "10.3.0.0/28"
domain                        = "example.com"
cloud_dns_zone_name           = "gcp-public-zone"
control_plane_open            = true
```

## Estimated Cost

```table
module.gke.google_container_node_pool.pools["assignmentnonprod-node-pool"]
 ├─ Instance usage (Linux/UNIX, on-demand, e2-standard-4) 730 hours $120.69
 └─ SSD provisioned storage (pd-ssd) 40 GB $7.48

module.gke.google_container_cluster.primary
 ├─ Cluster management fee 730 hours $73.00

google_compute_global_address.static
 └─ IP address (unused) 730 hours $7.30

module.cloud-nat.google_compute_router_nat.main
 └─ Data processed Monthly cost depends on usage: $0.045 per GB

google_dns_record_set.dns
 └─ Queries Monthly cost depends on usage: $0.40 per 1M queries

OVERALL TOTAL $208.47
```

## Running Terraform Locally

```sh
export GOOGLE_APPLICATION_CREDENTIALS="/path/key/file.json"
export TF_BACKEND_BUCKET="bucket_name_example"
export TF_BACKEND_PATH="prefix_example"

touch terraform.tfvars
terraform init -backend-config="bucket=${TF_BACKEND_BUCKET}" -backend-config="prefix=${TF_BACKEND_PATH}"
terraform plan -out=tfplan && terraform apply tfplan
```

## Post Creation (ArgoCD, ExternalDNS)

```sh
# Must be reachable to the cluster
bash ./post/argocd-install.sh --install
bash ./post/argocd-install.sh --update_proxy

# Apply ExternalDNS configuration
kubectl apply -f ./post/external-dns.yaml
# resource "google_dns_record_set" "dns" {
#   name         = "argocd.${var.domain}."
#   type         = "A"
#   ttl          = 300
#   project      = var.project_id
#   managed_zone = data.google_dns_managed_zone.dns_zone.name
#   rrdatas      = [google_compute_global_address.static.address]
# }
```

## GitHub Actions Workflow

Ensure the following secrets are set in your GitHub repository:

- `GOOGLE_APPLICATION_CREDENTIALS`: The JSON key for your Google Cloud service account.
- `TF_BACKEND_BUCKET`: The name of the Terraform backend bucket.
- `TF_BACKEND_PATH`: The path for the Terraform backend.

## Acknowledgements

- Terraform can be used to install Argo CD, but this requires allowing `0.0.0.0/0` in the GKE Cluster Control Plane (the provider will check the connection every time, for example, GitHub Action runner). Alternatively, you can split a new Terraform directory and use Terraform config to install Argo CD after the GKE Cluster is created.
- For the application external load balancer, consider adding Cloud Armor (WAF) for enhanced security.
- For the ArgoCD UI, consider using an internal load balancer and accessing it via a private network (VPN) or by whitelisting IPs with Cloud Armor.
- Although the GKE cluster has a public IP with a whitelist to allow CICD/Local access, it is recommended to use a fully private cluster and a self-hosted agent like Jenkins to access the GKE cluster.
- Set `control_plane_open` to true if you want to access the GKE Cluster. We recommend disabling it.
