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
Name                                                                           Monthly Qty  Unit              Monthly Cost   
                                                                                                                              
module.gke.google_container_cluster.primary                                                                                  
├─ Cluster management fee                                                              730  hours                   $73.00   
                                                                                                                              
module.gke.google_container_node_pool.pools["assignmentnonprod-node-pool"]                                                   
├─ Instance usage (Linux/UNIX, on-demand, e2-standard-2)                               730  hours                   $60.35   
└─ SSD provisioned storage (pd-ssd)                                                     40  GB                       $7.48   
                                                                                                                              
module.cloud-nat.google_compute_router_nat.main                                                                              
└─ Data processed                                                           Monthly cost depends on usage: $0.045 per GB     
                                                                                                                              
OVERALL TOTAL                                                                                                        $140.83          
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

# Get Kubeconfig
gcloud container clusters get-credentials <cluster_name> --region=<region>

## Todo : 1 script post
bash ./post/install-update-controller.sh --install-update-argocd
bash ./post/install-update-controller.sh --install-update-external-dns


```

## GitHub Actions Workflow

Ensure the following secrets are set in your GitHub repository:

- `GOOGLE_APPLICATION_CREDENTIALS`: The JSON key for your Google Cloud service account.
- `TF_BACKEND_BUCKET`: The name of the Terraform backend bucket.
- `TF_BACKEND_PATH`: The path for the Terraform backend.

## Acknowledgements

- **Terraform and ArgoCD Integration**: While Terraform can install Argo CD, it requires allowing `0.0.0.0/0` in the GKE Cluster Control Plane. This is necessary because the provider checks the connection each time, such as during GitHub Action runner executions. Alternatively, consider creating a separate Terraform directory and using Terraform configurations to install Argo CD after the GKE Cluster is created.
- **Security Enhancements**:
    - For the application external load balancer, consider adding Cloud Armor (WAF) for enhanced security.
    - For the Argo CD UI, consider using an internal load balancer and accessing it via a private network (VPN) or by whitelisting IPs with Cloud Armor.
    - Although the GKE cluster has a public IP with a whitelist to allow CICD/Local access, it is recommended to use a fully private cluster and a self-hosted agent like Jenkins to access the GKE cluster.
- **ExternalDNS Limitations**: ExternalDNS does not currently support creating records with routing policies in Google Cloud DNS. This feature could be leveraged to support geolocation routing, which can be more cost-effective for protecting the external load balancer (e.g., redirecting clients from specific geolocations to an empty site).
- **Control Plane Security**: Set `control_plane_open` to true if you need to access the GKE Cluster. However, it is recommended to disable it to enhance security.
- **GKE Gateway Controller**: For GCP, consider using the GKE Gateway controller instead of the GKE Ingress controller. This enables integration with deployment strategies like Argo Rollouts and simplifies operations across teams (e.g., cross-namespace routing, role-based access). The GCP Gateway controller is intended to replace the Ingress controller, with the latest updates in June 2023 and September 2024, respectively.
