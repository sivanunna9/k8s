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

Your Ingress is using:

alb.ingress.kubernetes.io/target-type: ip

The ip means ALB sends traffic directly to Pod IPs, not to EC2 node ports.

Your current flow:

                 Internet
                    |
                    |
                    v
        +----------------------+
        |  AWS Application     |
        |  Load Balancer (ALB) |
        +----------------------+
                    |
                    |
        target-type: ip
                    |
                    v
        +----------------------+
        | Kubernetes Ingress   |
        | aws-load-balancer    |
        | controller           |
        +----------------------+
                    |
                    |
                    v
        +----------------------+
        | train-app Service    |
        | ClusterIP:8080       |
        +----------------------+
                    |
                    |
                    v
        +----------------------+
        | train-app Pod        |
        | 192.168.87.255:8080  |
        | Tomcat Application   |
        +----------------------+

Your Ingress shows:

Backends:
train-app:8080 (192.168.87.255:8080)

That IP is the Pod IP.

Complete EKS architecture with your Oracle DB
                         Users
                           |
                           |
                           v
                 +----------------+
                 | Internet       |
                 +----------------+
                           |
                           |
                           v
             +---------------------------+
             | AWS ALB                  |
             | internet-facing           |
             | port 80                   |
             +---------------------------+
                           |
                           |
                           v
              Kubernetes Ingress
              ingressClassName: alb
                           |
                           |
                           v
              +------------------------+
              | train-app Service       |
              | ClusterIP : 8080       |
              +------------------------+
                           |
                           |
                           v

              +------------------------+
              | train-app Pod           |
              | Tomcat + Java app       |
              | port 8080               |
              +------------------------+
                           |
                           |
                           |
                           v

              +------------------------+
              | oracle-db Service       |
              | Headless ClusterIP None |
              | port 1521               |
              +------------------------+
                           |
                           |
                           v

              +------------------------+
              | Oracle StatefulSet      |
              | oracle-db-0             |
              | gvenzl/oracle-xe:21     |
              +------------------------+
                           |
                           |
                           v

              +------------------------+
              | EBS CSI Driver          |
              |                         |
              | EBS Volume 10Gi         |
              +------------------------+
Why use ip instead of instance?

ip:

ALB
 |
 v
Pod IP

Advantages:

No NodePort
Direct pod routing
Better scaling
Recommended for EKS

instance:

ALB
 |
 v
EC2 Node
 |
 v
NodePort
 |
 v
Pod
