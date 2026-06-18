#!/bin/bash

set -euo pipefail

#########################################
# CONFIGURATION
#########################################

CLUSTER_NAME="demo"
REGION="us-east-1"

export AWS_REGION=$REGION
export AWS_DEFAULT_REGION=$REGION

#########################################
# VARIABLES
#########################################

ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

echo "========================================="
echo "Cluster : ${CLUSTER_NAME}"
echo "Region  : ${REGION}"
echo "Account : ${ACCOUNT_ID}"
echo "========================================="

#########################################
# ENABLE OIDC
#########################################

echo ""
echo "Step 1: Associating OIDC Provider"

eksctl utils associate-iam-oidc-provider \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --approve

#########################################
# EBS CSI DRIVER
#########################################

echo ""
echo "Step 2: Creating EBS CSI IAM Role"

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster "${CLUSTER_NAME}" \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --role-only \
  --region "${REGION}" \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve || true

EBS_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole"

echo ""
echo "Step 3: Installing EBS CSI Addon"

eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --service-account-role-arn "${EBS_ROLE_ARN}" \
  --force || true

echo ""
echo "Waiting 30 seconds for EBS CSI pods..."
sleep 30

echo ""
echo "EBS CSI Driver Status"

kubectl get pods \
  -n kube-system \
  -l app.kubernetes.io/name=aws-ebs-csi-driver || true

#########################################
# EFS CSI DRIVER IAM
#########################################

echo ""
echo "Step 4: Downloading EFS IAM Policy"

curl -L -o iam-policy-example.json \
https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json

echo ""
echo "Step 5: Creating EFS IAM Policy"

aws iam create-policy \
  --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
  --policy-document file://iam-policy-example.json \
  || echo "Policy already exists"

#########################################
# GET OIDC
#########################################

OIDC_URL=$(aws eks describe-cluster \
  --name "${CLUSTER_NAME}" \
  --region "${REGION}" \
  --query "cluster.identity.oidc.issuer" \
  --output text)

OIDC_PROVIDER=$(echo "${OIDC_URL}" | sed 's#https://##')

echo ""
echo "OIDC Provider:"
echo "${OIDC_PROVIDER}"

#########################################
# TRUST POLICY
#########################################

echo ""
echo "Step 6: Creating Trust Policy"

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

#########################################
# CREATE EFS ROLE
#########################################

echo ""
echo "Step 7: Creating EFS IAM Role"

aws iam create-role \
  --role-name AmazonEKS_EFS_CSI_DriverRole \
  --assume-role-policy-document file://trust-policy.json \
  || echo "Role already exists"

echo ""
echo "Step 8: Attaching Policy"

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AmazonEKS_EFS_CSI_Driver_Policy \
  --role-name AmazonEKS_EFS_CSI_DriverRole \
  || true

#########################################
# SUMMARY
#########################################

echo ""
echo "========================================="
echo "SETUP COMPLETED"
echo "========================================="

echo ""
echo "EBS Role ARN:"
echo "${EBS_ROLE_ARN}"

echo ""
echo "EFS Role ARN:"
echo "arn:aws:iam::${ACCOUNT_ID}:role/AmazonEKS_EFS_CSI_DriverRole"

echo ""
echo "Verify EBS Driver:"
echo "kubectl get pods -n kube-system | grep ebs"

echo ""
echo "Next:"
echo "Install EFS CSI Driver Add-on or Helm Chart"
