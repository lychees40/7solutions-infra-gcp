#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [--install] [--update-proxy]"
  exit 1
}

# Initialize flags
INSTALL=false
UPDATE_PROXY=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --install)
      INSTALL=true
      ;;
    --update-proxy)
      UPDATE_PROXY=true
      ;;
    *)
      usage
      ;;
  esac
  shift
done

# Execute installation if --install flag is set
if $INSTALL; then
  echo "Installing or upgrading Argo CD with Helm..."

  # Add the Argo Helm repository if not already added
  if ! helm repo list | grep -q argo-helm; then
    helm repo add argo-helm https://argoproj.github.io/argo-helm
  fi

  # Update Helm repositories
  helm repo update

  # Deploy Argo CD with custom values and specify the chart version
  helm upgrade --install argo-cd argo-helm/argo-cd \
    --version 7.7.6 \
    --create-namespace \
    --namespace argocd \
    --values argocd-values.yaml

fi

# Execute proxy update if --update-proxy flag is set
if $UPDATE_PROXY; then
  echo "Updating target HTTPS proxy..."

  # Retrieve the status of the ManagedCertificate
  CERT_STATUS=$(kubectl get managedcertificate argo-cd-argocd-server -n argocd -o jsonpath='{.status.certificateStatus}')

  # Check if the ManagedCertificate is active
  if [ "$CERT_STATUS" == "Active" ]; then
    echo "ManagedCertificate is active. Skipping proxy update."
    exit 0
  fi

  # Retrieve the https-target-proxy annotation from the Ingress
  HTTPS_TARGET_PROXY=$(kubectl get ingress argo-cd-argocd-server -n argocd -o jsonpath='{.metadata.annotations.ingress\.kubernetes\.io/https-target-proxy}')

  # Check if the HTTPS_TARGET_PROXY was successfully retrieved
  if [ -z "$HTTPS_TARGET_PROXY" ]; then
    echo "Error: HTTPS_TARGET_PROXY annotation not found. Wait several minutes and try again."
    exit 1
  fi

  # Update the target HTTPS proxy with the specified certificate map
  gcloud compute target-https-proxies update "$HTTPS_TARGET_PROXY" --certificate-map="argo-cd-argocd-server"

  # Optional: Verify the update
  echo "Updated target HTTPS proxy '$HTTPS_TARGET_PROXY' with certificate map 'argo-cd-argocd-server'."
fi

# If no flags were provided, display usage
if ! $INSTALL && ! $UPDATE_PROXY; then
  usage
fi