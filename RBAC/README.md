# AWS EKS RBAC Setup for Multiple IAM Users

This documentation outlines the complete setup to enable four IAM users (`trainee`, `dev`, `admin`, and `super-admin`) to access an Amazon EKS cluster using Kubernetes RBAC.

---

## 📘 Overview

In AWS EKS, authentication is handled via AWS IAM, and authorization (what users can do inside the cluster) is handled via Kubernetes RBAC.

This document explains how to configure RBAC for four user types:

- **trainee** – Read-only access to all namespaces
- **dev** – Full access to a specific namespace
- **admin** – Full access to all namespaces
- **super-admin** – Full cluster-level admin

---

## 🔧 Components & Purpose

| Component             | Description |
|-----------------------|-------------|
| IAM User              | AWS IAM user identity used for login and authentication |
| aws-auth ConfigMap    | Maps IAM user to Kubernetes user/group for access inside the cluster |
| Role                  | Set of permissions limited to a specific namespace |
| ClusterRole           | Set of permissions across all namespaces (cluster-wide) |
| RoleBinding           | Assigns a Role to a user/group within a namespace |
| ClusterRoleBinding    | Assigns a ClusterRole to a user/group across the cluster |
| system:masters        | Built-in Kubernetes group with full admin privileges (used for super-admin) |

---

## 🪜 Step-by-Step Guide

### 🧑‍💻 Step 1: Create IAM Users

In the AWS Console, create IAM users:
- `trainee`
- `dev`
- `admin`
- `super-admin`

Give programmatic access and note their IAM User ARNs.

### 📥 Step 2: Update kubeconfig as EKS Admin

```bash
aws eks update-kubeconfig --name <your-cluster> --region <region>
kubectl get nodes  # Verify access
```

### ✅ Step 3: Set up AWS CLI for trainee user credentials

You need to configure AWS CLI with trainee's credentials on the machine where you'll run kubectl.

#### Option A: `aws configure` (Manual)

```bash
aws configure --profile trainee
```

Provide:
- Access key ID
- Secret access key
- Region
- Output format (e.g., json)

---

## 📝 Step 4: Define Kubernetes RBAC Roles

### 📄 4.1: trainee – Read-only access (ClusterRole)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: trainee-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
```

### 📄 4.2: dev – Full access to a namespace (dev-ns)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-role
  namespace: dev-ns
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
```

### 📄 4.3: admin – Full access across all namespaces

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admin-role
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

---

## 🔗 Step 5: Map IAM Users to Kubernetes Groups

### Edit the aws-auth ConfigMap:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Add this under `mapUsers`:

```yaml
mapUsers: |
  - userarn: arn:aws:iam::<account-id>:user/trainee
    username: trainee
    groups:
      - trainee-group
  - userarn: arn:aws:iam::<account-id>:user/dev
    username: dev
    groups:
      - dev-group
  - userarn: arn:aws:iam::<account-id>:user/admin
    username: admin
    groups:
      - admin-group
  - userarn: arn:aws:iam::<account-id>:user/super-admin
    username: super-admin
    groups:
      - system:masters
```

📝 `system:masters` gives `super-admin` full control of the cluster.

---

## 🔒 Step 6: Create RoleBindings

### 📄 trainee RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: trainee-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: trainee-role
subjects:
- kind: User
  name: trainee
  apiGroup: rbac.authorization.k8s.io
```

### 📄 dev RoleBinding (in dev-ns)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-binding
  namespace: dev-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev-role
subjects:
- kind: User
  name: dev
  apiGroup: rbac.authorization.k8s.io
```

### 📄 admin ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin-role
subjects:
- kind: User
  name: admin
  apiGroup: rbac.authorization.k8s.io
```

---

## 🚀 Step 7: Apply All YAML Files

```bash
kubectl apply -f trainee-role.yaml
kubectl apply -f trainee-binding.yaml

kubectl apply -f dev-role.yaml
kubectl apply -f dev-binding.yaml

kubectl apply -f admin-role.yaml
kubectl apply -f admin-binding.yaml
```

---

## 🗂️ Step 8: Provide Kubeconfig Access to Users

### Example for `trainee`:

```bash
aws eks update-kubeconfig   --region us-west-2   --name my-cluster   --profile trainee
```

---

## ✅ Summary Table

| User         | IAM Mapping     | RBAC Role     | Access Scope                   |
|--------------|------------------|----------------|--------------------------------|
| trainee      | trainee-group    | trainee-role   | Read-only (all namespaces)     |
| dev          | dev-group        | dev-role       | Full access (dev-ns)           |
| admin        | admin-group      | admin-role     | Full access (all namespaces)   |
| super-admin  | system:masters   | built-in role  | Full cluster admin             |
