#!/bin/bash

set -e

# -----------------------------
# Variables
# -----------------------------
CLUSTER_NAME="demo"
REGION="us-east-1"

BUCKET_NAME="demo-eks-backup-2026"

POLICY_NAME="VeleroBackupPolicy"
ROLE_NAME="VeleroRole"

NAMESPACE="velero"
SERVICE_ACCOUNT="velero"

ACCOUNT_ID=$(aws sts get-caller-identity \
--query Account \
--output text)

echo "Account: $ACCOUNT_ID"


# -----------------------------
# 1. Create S3 Bucket
# -----------------------------

echo "Creating S3 bucket..."

aws s3 mb s3://$BUCKET_NAME \
--region $REGION || true


echo "Enable versioning..."

aws s3api put-bucket-versioning \
--bucket $BUCKET_NAME \
--versioning-configuration Status=Enabled


# -----------------------------
# 2. Create IAM Policy
# -----------------------------

echo "Creating Velero IAM policy..."

cat > velero-policy.json <<EOF
{
 "Version":"2012-10-17",
 "Statement":[
   {
    "Effect":"Allow",
    "Action":[
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot"
    ],
    "Resource":"*"
   },
   {
    "Effect":"Allow",
    "Action":[
      "s3:*"
    ],
    "Resource":[
      "arn:aws:s3:::$BUCKET_NAME",
      "arn:aws:s3:::$BUCKET_NAME/*"
    ]
   }
 ]
}
EOF


aws iam create-policy \
--policy-name $POLICY_NAME \
--policy-document file://velero-policy.json \
|| true


POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"


# -----------------------------
# 3. Create Namespace
# -----------------------------

kubectl create namespace $NAMESPACE \
|| true


# -----------------------------
# 4. IRSA Service Account
# -----------------------------

echo "Creating Velero IAM service account..."

eksctl create iamserviceaccount \
--cluster $CLUSTER_NAME \
--namespace $NAMESPACE \
--name $SERVICE_ACCOUNT \
--role-name $ROLE_NAME \
--attach-policy-arn $POLICY_ARN \
--approve \
--region $REGION \
--override-existing-serviceaccounts


# -----------------------------
# 5. Install Velero CLI
# -----------------------------

if ! command -v velero >/dev/null
then

echo "Installing Velero CLI..."

curl -L \
https://github.com/vmware-tanzu/velero/releases/download/v1.16.0/velero-v1.16.0-linux-amd64.tar.gz \
-o velero.tar.gz


tar -xvf velero.tar.gz


sudo mv \
velero-v1.16.0-linux-amd64/velero \
/usr/local/bin/

fi


velero version


# -----------------------------
# 6. Install Velero in EKS
# -----------------------------

echo "Installing Velero..."

velero install \
--provider aws \
--plugins velero/velero-plugin-for-aws:v1.10.0 \
--bucket $BUCKET_NAME \
--backup-location-config region=$REGION \
--snapshot-location-config region=$REGION \
--use-node-agent \
--service-account-name $SERVICE_ACCOUNT \
--namespace $NAMESPACE


# -----------------------------
# 7. Verify
# -----------------------------

echo "Waiting for Velero..."

kubectl get pods -n $NAMESPACE


echo ""
echo "================================="
echo "Velero Installed Successfully"
echo "================================="

echo "Create backup:"
echo ""
echo "velero backup create demo-backup --include-namespaces '*'"
echo ""

echo "Check:"
echo "velero backup get"
