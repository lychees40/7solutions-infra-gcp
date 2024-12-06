#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [--install-update-argocd] [--install-update-external-dns] [--external-dns-version <version>]"
  exit 1
}

# Initialize flags and variables
UPDATE_ARGOCD=false
UPDATE_EXTERNAL_DNS=false
EXTERNALDNS_IMAGE_VERSION="0.15.0"
ARGOCD_HELM_VERSION="7.7.0"

# Display current versions
echo "Current External DNS Image Version: ${EXTERNALDNS_IMAGE_VERSION}"
echo "Current Argo CD Helm Chart Version: ${ARGOCD_HELM_VERSION}"

# Function to check command availability
check_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: $1 is not installed."
    exit 1
  }
}

# Verify required commands are available
check_command helm
check_command kubectl
check_command sed

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
  --install-update-argocd)
    UPDATE_ARGOCD=true
    ;;
  --install-update-external-dns)
    UPDATE_EXTERNAL_DNS=true
    ;;
  --external-dns-version)
    if [[ -n $2 && ! $2 =~ ^-- ]]; then
      EXTERNALDNS_IMAGE_VERSION=$2
      shift
    else
      echo "Error: --external-dns-version requires a version number."
      usage
    fi
    ;;
  *)
    usage
    ;;
  esac
  shift
done

# Execute Argo CD update if --install-update-argocd flag is set
if $UPDATE_ARGOCD; then
  echo "Updating Argo CD with Helm..."

  # Add the Argo Helm repository if not already added
  if ! helm repo list | grep -q argo-helm; then
    helm repo add argo-helm https://argoproj.github.io/argo-helm
  fi

  # Update Helm repositories
  helm repo update

  # Deploy Argo CD with custom values and specify the chart version
  helm upgrade --install argo-cd argo-helm/argo-cd \
    --version "$ARGOCD_HELM_VERSION" \
    --create-namespace \
    --namespace argocd \
    --values argocd-values.yaml
fi

# Execute External DNS update if --install-update-external-dns flag is set
if $UPDATE_EXTERNAL_DNS; then
  echo "Installing or Updating External DNS"

  # Update the image tag in external-dns.yaml
  sed -i '' "s|image: registry.k8s.io/external-dns/external-dns:.*|image: registry.k8s.io/external-dns/external-dns:v${EXTERNALDNS_IMAGE_VERSION}|g" external-dns.yaml
  # Apply External DNS configuration
  kubectl apply -f external-dns.yaml
fi

# If no flags were provided, display usage
if ! $UPDATE_ARGOCD && ! $UPDATE_EXTERNAL_DNS; then
  usage
fi
