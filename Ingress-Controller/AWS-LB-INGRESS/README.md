# AWS Load Balancer Controller Setup on EKS

This README installs the AWS Load Balancer Controller on an Amazon EKS cluster.

It will configure:

- IAM OIDC provider
- IAM policy
- IAM service account
- Helm installation
- AWS Load Balancer Controller
- ALB Ingress


## Architecture
Browser
|
v
AWS Application Load Balancer
|
v
AWS Load Balancer Controller
|
v
Kubernetes Ingress
|
v
ClusterIP Service
|
v
Tomcat Pod



# Prerequisites

Install:

- AWS CLI
- kubectl
- eksctl
- Helm v3


Verify:

```bash
aws --version
kubectl version --client
eksctl version
helm version

Configure AWS:

aws configure
Environment

Change values if required:

CLUSTER_NAME=demo
REGION=us-east-1
