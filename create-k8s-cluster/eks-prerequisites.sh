#!/usr/bin/env bash

set -euo pipefail

echo "Updating packages..."
sudo apt-get update -y
sudo apt-get install -y curl unzip jq

########################################
# AWS CLI (Latest)
########################################

echo "Installing latest AWS CLI..."

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        AWS_ARCH="x86_64"
        ;;
    aarch64|arm64)
        AWS_ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o awscliv2.zip

rm -rf aws
unzip -q awscliv2.zip
sudo ./aws/install --update

aws --version

########################################
# kubectl (Latest EKS Version)
########################################

echo "Installing latest kubectl..."

LATEST_K8S=$(curl -fsSL https://dl.k8s.io/release/stable.txt)

curl -fsSL \
  -o kubectl \
  "https://dl.k8s.io/release/${LATEST_K8S}/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/

kubectl version --client

########################################
# eksctl (Latest Release)
########################################

echo "Installing latest eksctl..."

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        EKSCTL_ARCH="amd64"
        ;;
    aarch64|arm64)
        EKSCTL_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

EKSCTL_VERSION=$(curl -fsSL \
  https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
  | jq -r '.tag_name')

curl -fsSL \
  "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${EKSCTL_ARCH}.tar.gz" \
  -o eksctl.tar.gz

tar -xzf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/

eksctl version

########################################
# Configure AWS CLI
########################################

echo ""
echo "Installation complete."
echo "Configure AWS credentials using:"
echo "aws configure"
