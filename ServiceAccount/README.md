# 🔐 Service Accounts in AWS EKS

This guide explains what **Kubernetes Service Accounts** are, how they integrate with **AWS IAM Roles for Service Accounts (IRSA)**, and how to use them securely in an **Amazon EKS** cluster.

---

## 📘 What is a Kubernetes Service Account?

A **Service Account** in Kubernetes provides an identity for processes running in a pod. It is used to access the Kubernetes API and external resources securely.

---

## 🔄 IAM Roles for Service Accounts (IRSA)

Amazon EKS supports associating IAM roles with Kubernetes Service Accounts to grant fine-grained AWS permissions to applications running on EKS.

---

## ✅ Prerequisites

- An existing EKS cluster
- `eksctl` installed
- `kubectl` configured
- OIDC provider enabled on your cluster

---

## 🔧 Step-by-Step Guide to Setup IRSA

### Step 1: Associate OIDC Provider with EKS Cluster

```bash
eksctl utils associate-iam-oidc-provider   --region <region>   --cluster <cluster-name>   --approve
```

---

### Step 2: Create an IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }
  ]
}
```

Save this as `s3-access-policy.json`, then run:

```bash
aws iam create-policy   --policy-name S3ReadAccess   --policy-document file://s3-access-policy.json
```

---

### Step 3: Create Service Account with IAM Role using `eksctl`

```bash
eksctl create iamserviceaccount   --name s3-reader   --namespace default   --cluster <cluster-name>   --attach-policy-arn arn:aws:iam::<account-id>:policy/S3ReadAccess   --approve   --override-existing-serviceaccounts
```

---

## 📦 Example Pod Using the Service Account

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: s3-app
spec:
  serviceAccountName: s3-reader
  containers:
  - name: s3-container
    image: amazonlinux
    command: ["/bin/sh"]
    args: ["-c", "sleep 3600"]
```

---

## 🔍 Verifying IAM Role Access from Pod

After deploying the pod:

```bash
kubectl exec -it s3-app -- bash
yum install -y aws-cli
aws s3 ls s3://your-bucket-name
```

You should see the bucket contents if access is granted correctly.

---

## ✅ Summary

| Feature                  | Description |
|--------------------------|-------------|
| **Service Account**      | Kubernetes identity for pods |
| **IAM Role for SA (IRSA)** | Grants AWS permissions via IAM |
| **Secure Access**        | Avoids hardcoding credentials in pods |
| **Fine-Grained Control** | One pod = one IAM role for least privilege |

---

## 📚 References

- [Amazon EKS IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [EKS Best Practices - Security](https://aws.github.io/aws-eks-best-practices/security/docs/iam/)
