#!/bin/bash

set -e


CLUSTER_NAME="demo"
REGION="us-east-1"

NAMESPACE="kube-system"

SERVICE_ACCOUNT="aws-load-balancer-controller"

POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"


echo "=================================="
echo "Installing AWS Load Balancer Controller"
echo "=================================="


echo "Step 1: Associate OIDC"


eksctl utils associate-iam-oidc-provider \
--cluster $CLUSTER_NAME \
--region $REGION \
--approve



echo "Step 2: Download IAM Policy"


curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json



ACCOUNT_ID=$(aws sts get-caller-identity \
--query Account \
--output text)


echo "AWS Account: $ACCOUNT_ID"



echo "Step 3: Create IAM Policy"


aws iam create-policy \
--policy-name $POLICY_NAME \
--policy-document file://iam_policy.json \
|| echo "Policy already exists"



POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME"



echo "Step 4: Create IAM Service Account"



eksctl create iamserviceaccount \
--cluster $CLUSTER_NAME \
--namespace $NAMESPACE \
--name $SERVICE_ACCOUNT \
--attach-policy-arn $POLICY_ARN \
--approve \
--region $REGION \
|| echo "Service account exists"



echo "Step 5: Install Helm"



if ! command -v helm
then

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

fi



helm repo add eks https://aws.github.io/eks-charts

helm repo update



echo "Step 6: Get VPC ID"


VPC_ID=$(aws eks describe-cluster \
--name $CLUSTER_NAME \
--region $REGION \
--query "cluster.resourcesVpcConfig.vpcId" \
--output text)


echo "VPC: $VPC_ID"



echo "Step 7: Install AWS Load Balancer Controller"



helm upgrade --install aws-load-balancer-controller \
eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=$SERVICE_ACCOUNT \
--set region=$REGION \
--set vpcId=$VPC_ID



echo "Waiting for controller"


kubectl rollout status deployment/aws-load-balancer-controller \
-n kube-system



echo "Installation completed"



kubectl get pods -n kube-system | grep aws-load-balancers
