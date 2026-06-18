#!/bin/bash

set -e

#####################################
# CONFIG
#####################################

CLUSTER="demo"
REGION="us-east-1"

NAMESPACE="velero"
BUCKET="demo-eks-backup-2026"

ROLE_NAME="VeleroRole"

PLUGIN="velero/velero-plugin-for-aws:v1.10.0"


#####################################
# REMOVE OLD INSTALL
#####################################

echo "================================="
echo "Removing old Velero"
echo "================================="

velero uninstall \
--namespace $NAMESPACE \
--force || true


kubectl delete namespace $NAMESPACE \
--ignore-not-found=true || true


echo "Waiting namespace cleanup..."

while kubectl get namespace $NAMESPACE >/dev/null 2>&1
do
    sleep 5
done


#####################################
# CREATE NAMESPACE
#####################################

echo "Creating namespace"

kubectl create namespace $NAMESPACE



#####################################
# CREATE IAM POLICY
#####################################

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
    "ec2:CreateTags"
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
--policy-name VeleroBackupPolicy \
--policy-document file://velero-policy.json \
--query Policy.Arn \
--output text 2>/dev/null || \
aws iam list-policies \
--query "Policies[?PolicyName=='VeleroBackupPolicy'].Arn" \
--output text)



#####################################
# CREATE IRSA
#####################################


echo "Creating Velero IRSA"


eksctl create iamserviceaccount \
--cluster $CLUSTER \
--namespace $NAMESPACE \
--name velero \
--role-name $ROLE_NAME \
--attach-policy-arn $POLICY_ARN \
--approve \
--region $REGION \
--override-existing-serviceaccounts || true



#####################################
# SERVICE ACCOUNT FALLBACK
#####################################


echo "Checking ServiceAccount"


kubectl get serviceaccount velero \
-n $NAMESPACE >/dev/null 2>&1 || {

echo "Creating missing ServiceAccount"

kubectl create serviceaccount velero \
-n $NAMESPACE

}



#####################################
# IAM ANNOTATION
#####################################


echo "Annotating ServiceAccount"


ROLE_ARN=$(aws iam get-role \
--role-name $ROLE_NAME \
--query Role.Arn \
--output text)


kubectl annotate serviceaccount velero \
-n $NAMESPACE \
eks.amazonaws.com/role-arn=$ROLE_ARN \
--overwrite



#####################################
# RBAC
#####################################


echo "Creating RBAC"


kubectl create clusterrolebinding velero \
--clusterrole=cluster-admin \
--serviceaccount=$NAMESPACE:velero \
--dry-run=client -o yaml | kubectl apply -f -



#####################################
# INSTALL VELERO
#####################################


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



#####################################
# RESTART
#####################################


echo "Restarting Velero"


kubectl rollout restart deployment/velero \
-n $NAMESPACE || true


kubectl rollout restart daemonset/node-agent \
-n $NAMESPACE || true



#####################################
# WAIT
#####################################


echo "Waiting for pods"


sleep 30


kubectl wait \
--for=condition=Ready pod \
-l component=velero \
-n $NAMESPACE \
--timeout=300s || true



#####################################
# VERIFY
#####################################


echo "================================="
echo "Velero Status"
echo "================================="


kubectl get pods -n $NAMESPACE


echo ""
echo "ServiceAccount"

kubectl get sa velero -n $NAMESPACE


echo ""
echo "velero backup create demo-backup --include-namespaces '*'"
echo ""

echo "Check:"
echo "velero backup get"


echo "Backup Location"

velero backup-location get



echo ""
