#!/bin/bash

set -e

########################################
# CONFIG
########################################

CLUSTER="demo"
REGION="us-east-1"

NAMESPACE="velero"
BUCKET="demo-eks-backup-2026"

ROLE_NAME="VeleroRole"
POLICY_NAME="VeleroBackupPolicy"

PLUGIN="velero/velero-plugin-for-aws:v1.10.0"


########################################
# REMOVE OLD VELERO
########################################

echo "================================="
echo "Removing old Velero"
echo "================================="

velero uninstall \
  --namespace $NAMESPACE \
  --force || true


kubectl delete clusterrolebinding velero \
  --ignore-not-found=true || true


kubectl delete namespace $NAMESPACE \
  --ignore-not-found=true || true


echo "Waiting namespace deletion..."

while kubectl get namespace $NAMESPACE >/dev/null 2>&1
do
  sleep 5
done



########################################
# CREATE NAMESPACE
########################################

echo "Creating namespace"

kubectl create namespace $NAMESPACE



########################################
# CREATE S3 BUCKET
########################################

echo "Checking S3 bucket"

aws s3api head-bucket \
 --bucket $BUCKET 2>/dev/null || {

aws s3 mb s3://$BUCKET \
 --region $REGION

}


aws s3api put-bucket-versioning \
 --bucket $BUCKET \
 --versioning-configuration Status=Enabled



########################################
# IAM POLICY
########################################

echo "Creating IAM policy"


cat > velero-policy.json <<EOF
{
 "Version":"2012-10-17",
 "Statement":[
  {
   "Effect":"Allow",
   "Action":[
    "ec2:DescribeVolumes",
    "ec2:DescribeSnapshots",
    "ec2:DescribeSnapshotAttribute",
    "ec2:CreateSnapshot",
    "ec2:DeleteSnapshot",
    "ec2:CreateTags",
    "ec2:DescribeAvailabilityZones"
   ],
   "Resource":"*"
  },
  {
   "Effect":"Allow",
   "Action":[
    "s3:*"
   ],
   "Resource":[
    "arn:aws:s3:::$BUCKET",
    "arn:aws:s3:::$BUCKET/*"
   ]
  }
 ]
}
EOF



POLICY_ARN=$(aws iam create-policy \
 --policy-name $POLICY_NAME \
 --policy-document file://velero-policy.json \
 --query Policy.Arn \
 --output text 2>/dev/null || true)



if [ -z "$POLICY_ARN" ]
then

POLICY_ARN=$(aws iam list-policies \
 --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" \
 --output text)

fi


echo $POLICY_ARN



########################################
# CREATE IAM ROLE + SA
########################################

echo "Creating IRSA"


eksctl create iamserviceaccount \
 --cluster $CLUSTER \
 --namespace $NAMESPACE \
 --name velero \
 --role-name $ROLE_NAME \
 --attach-policy-arn $POLICY_ARN \
 --approve \
 --region $REGION \
 --override-existing-serviceaccounts || true



########################################
# ENSURE SERVICE ACCOUNT
########################################

echo "Ensuring ServiceAccount"


kubectl create serviceaccount velero \
 -n $NAMESPACE \
 --dry-run=client -o yaml | kubectl apply -f -



########################################
# ANNOTATE SA
########################################


ROLE_ARN=$(aws iam get-role \
 --role-name $ROLE_NAME \
 --query Role.Arn \
 --output text)


kubectl annotate serviceaccount velero \
 -n $NAMESPACE \
 eks.amazonaws.com/role-arn=$ROLE_ARN \
 --overwrite



########################################
# RBAC (IMPORTANT)
########################################

echo "Creating RBAC"


kubectl create clusterrolebinding velero \
 --clusterrole cluster-admin \
 --serviceaccount velero:velero \
 --dry-run=client -o yaml | kubectl apply -f -



########################################
# VERIFY
########################################


echo "Checking SA"

kubectl get sa velero -n $NAMESPACE


echo "Checking RBAC"

kubectl get clusterrolebinding velero



########################################
# INSTALL VELERO
########################################


echo "Installing Velero"


velero install \
 --namespace $NAMESPACE \
 --provider aws \
 --plugins $PLUGIN \
 --bucket $BUCKET \
 --backup-location-config region=$REGION \
 --snapshot-location-config region=$REGION \
 --use-node-agent \
 --service-account-name velero \
 --no-secret



########################################
# WAIT
########################################


echo "Waiting for deployment"


sleep 30


kubectl rollout status deployment/velero \
 -n $NAMESPACE \
 --timeout=300s || true



########################################
# STATUS
########################################


echo "================================="
echo "VELERO STATUS"
echo "================================="


kubectl get pods -n $NAMESPACE


echo ""
echo "Logs"

kubectl logs deployment/velero \
 -n $NAMESPACE \
 --tail=50 || true



echo ""
echo "Backup location"

velero backup-location get



echo ""
echo "Create backup:"
echo "velero backup create demo-backup --include-namespaces '*'"

echo ""
echo "Check:"
echo "velero backup get"
