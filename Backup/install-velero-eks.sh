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
POLICY_NAME="VeleroBackupPolicy"

PLUGIN="velero/velero-plugin-for-aws:v1.10.0"

#####################################

# REMOVE OLD INSTALL

#####################################

echo "================================="
echo "Removing old Velero"
echo "================================="

velero uninstall 
--namespace ${NAMESPACE} 
--force || true

kubectl delete clusterrolebinding velero 
--ignore-not-found=true || true

kubectl delete namespace ${NAMESPACE} 
--ignore-not-found=true || true

echo "Waiting for namespace deletion..."

while kubectl get namespace ${NAMESPACE} >/dev/null 2>&1
do
sleep 5
done

#####################################

# CREATE NAMESPACE

#####################################

echo "================================="
echo "Creating namespace"
echo "================================="

kubectl create namespace ${NAMESPACE}

#####################################

# CREATE IAM POLICY

#####################################

echo "================================="
echo "Creating IAM policy"
echo "================================="

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
"ec2:CreateVolume",
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
"arn:aws:s3:::${BUCKET}",
"arn:aws:s3:::${BUCKET}/*"
]
}
]
}
EOF

POLICY_ARN=$(aws iam create-policy 
--policy-name ${POLICY_NAME} 
--policy-document file://velero-policy.json 
--query Policy.Arn 
--output text 2>/dev/null || true)

if [ -z "$POLICY_ARN" ]; then
POLICY_ARN=$(aws iam list-policies 
--query "Policies[?PolicyName=='${POLICY_NAME}'].Arn" 
--output text)
fi

echo "Policy ARN: ${POLICY_ARN}"

#####################################

# CREATE IRSA

#####################################

echo "================================="
echo "Creating IRSA"
echo "================================="

eksctl create iamserviceaccount 
--cluster ${CLUSTER} 
--namespace ${NAMESPACE} 
--name velero 
--role-name ${ROLE_NAME} 
--attach-policy-arn ${POLICY_ARN} 
--approve 
--region ${REGION} 
--override-existing-serviceaccounts

#####################################

# VERIFY SERVICE ACCOUNT

#####################################

echo "================================="
echo "Checking ServiceAccount"
echo "================================="

kubectl get sa velero -n ${NAMESPACE}

#####################################

# GET ROLE ARN

#####################################

ROLE_ARN=$(aws iam get-role 
--role-name ${ROLE_NAME} 
--query Role.Arn 
--output text)

echo "Role ARN: ${ROLE_ARN}"

#####################################

# ANNOTATE SERVICE ACCOUNT

#####################################

kubectl annotate serviceaccount velero 
-n ${NAMESPACE} 
eks.amazonaws.com/role-arn=${ROLE_ARN} 
--overwrite

#####################################

# INSTALL VELERO

#####################################

echo "================================="
echo "Installing Velero"
echo "================================="

velero install 
--namespace ${NAMESPACE} 
--provider aws 
--plugins ${PLUGIN} 
--bucket ${BUCKET} 
--backup-location-config region=${REGION} 
--snapshot-location-config region=${REGION} 
--use-node-agent 
--service-account-name velero 
--no-secret

#####################################

# RE-ANNOTATE SERVICE ACCOUNT

#####################################

kubectl annotate serviceaccount velero 
-n ${NAMESPACE} 
eks.amazonaws.com/role-arn=${ROLE_ARN} 
--overwrite

#####################################

# CREATE CLUSTERROLEBINDING

#####################################

echo "================================="
echo "Creating ClusterRoleBinding"
echo "================================="

kubectl delete clusterrolebinding velero 
--ignore-not-found=true

kubectl create clusterrolebinding velero 
--clusterrole=cluster-admin 
--serviceaccount=velero:velero

#####################################

# VERIFY RBAC

#####################################

echo "================================="
echo "Verifying RBAC"
echo "================================="

kubectl auth can-i get namespaces 
--as=system:serviceaccount:velero:velero

#####################################

# RESTART VELERO PODS

#####################################

echo "================================="
echo "Restarting Velero Pods"
echo "================================="

kubectl delete pod -n ${NAMESPACE} --all || true

#####################################

# WAIT

#####################################

echo "================================="
echo "Waiting for pods"
echo "================================="

sleep 30

kubectl get pods -n ${NAMESPACE}

#####################################

# VERIFY

#####################################

echo ""
echo "================================="
echo "Velero Pods"
echo "================================="
kubectl get pods -n ${NAMESPACE}

echo ""
echo "================================="
echo "ServiceAccount"
echo "================================="
kubectl get sa velero -n ${NAMESPACE}

echo ""
echo "================================="
echo "Role Annotation"
echo "================================="
kubectl get sa velero -n ${NAMESPACE} -o yaml | grep role-arn

echo ""
echo "================================="
echo "Backup Locations"
echo "================================="
velero backup-location get

echo ""
echo "================================="
echo "Test Backup Command"
echo "================================="
echo "velero backup create demo-backup --include-namespaces '*'"

echo ""
echo "Check backup:"
echo "velero backup get"

echo ""
echo "Done"
