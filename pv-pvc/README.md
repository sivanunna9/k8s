# 📦 Persistent Volumes (PV) and Persistent Volume Claims (PVC) in AWS EKS

This guide explains how to use **Persistent Volumes (PV)** and **Persistent Volume Claims (PVC)** in **Amazon EKS** with **Amazon EBS** and **Amazon EFS** for durable, scalable storage.

---

## 🔹 What is a Persistent Volume (PV)?

A **Persistent Volume (PV)** is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned using StorageClasses.

---

## 🔸 What is a Persistent Volume Claim (PVC)?

A **Persistent Volume Claim (PVC)** is a request for storage by a user. It specifies size, access modes, and storage class.

---

## 💾 Using EBS as Storage in EKS

Amazon EBS is suitable for block-level storage for a single pod in a single AZ.

### ✅ Step 1: Create a StorageClass for EBS

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
```

---

### ✅ Step 2: Create a PVC Using the EBS StorageClass

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 5Gi
```

---

### ✅ Step 3: Use the PVC in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-using-ebs
spec:
  containers:
    - name: app
      image: busybox
      command: [ "sleep", "3600" ]
      volumeMounts:
        - mountPath: "/data"
          name: ebs-volume
  volumes:
    - name: ebs-volume
      persistentVolumeClaim:
        claimName: ebs-pvc
```

---

## 📂 Using EFS as Storage in EKS

Amazon EFS is suitable for shared, scalable file storage across multiple pods and AZs.

### ✅ Step 1: Create a StorageClass for EFS

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

---

### ✅ Step 2: Create a PVC Using the EFS StorageClass

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

---

### ✅ Step 3: Use the PVC in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-using-efs
spec:
  containers:
    - name: app
      image: busybox
      command: [ "sleep", "3600" ]
      volumeMounts:
        - mountPath: "/efs"
          name: efs-volume
  volumes:
    - name: efs-volume
      persistentVolumeClaim:
        claimName: efs-pvc
```

---

## 🔁 Summary

| Feature | EBS | EFS |
|--------|-----|-----|
| Access Mode | ReadWriteOnce | ReadWriteMany |
| AZ Scope | Single AZ | Multi-AZ |
| Use Case | Single pod/block storage | Shared/multiple pod access |
| CSI Driver | `ebs.csi.aws.com` | `efs.csi.aws.com` |

---

Ensure the respective CSI drivers (EBS or EFS) are installed on your EKS cluster. These can be installed via Helm or `eksctl`.

# Append EBS and EFS CSI driver installation steps 
---

## ⚙️ Installing EBS and EFS CSI Drivers on EKS

To use Persistent Volumes backed by AWS EBS or EFS, you must install the respective CSI drivers.

---

### 📦 1. Install EBS CSI Driver using `eksctl`
The IAM OIDC Provider is not enabled by default, you can use the following command to enable it, or use config file (see below):

```bash
eksctl utils associate-iam-oidc-provider --cluster=<your-cluster-name> --region=provide region> 


eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster <your-cluster-name>  \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --role-only \
		    --region <provide region>  \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve

eksctl create addon \\
  --name aws-ebs-csi-driver \\
  --cluster <your-cluster-name> \\
  --service-account-role-arn arn:aws:iam::<account-id>:role/AmazonEKS_EBS_CSI_DriverRole \\
  --force

✅ Check driver status:

kubectl get pods -n kube-system -l "app.kubernetes.io/name=aws-ebs-csi-driver"



# Setting up EFS as Persistent Volume in AWS EKS

## 📋 Prerequisites

Before deploying the CSI driver, create an IAM role that allows the CSI driver’s service account to make calls to AWS APIs on your behalf.

---

## 📄 Step-by-Step Instructions

### 1. Download the IAM policy document

```bash
curl -o iam-policy-example.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/v1.2.0/docs/iam-policy-example.json
```

### 2. Create an IAM policy

```bash
aws iam create-policy \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://iam-policy-example.json
```

### 3. Get OIDC provider

```bash
aws eks describe-cluster --name your_cluster_name --query "cluster.identity.oidc.issuer" --output text
```

> Replace `your_cluster_name` with your actual EKS cluster name.

### 4. Create trust policy

```json
cat <<EOF > trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF
```

### 5. Create IAM role

```bash
aws iam create-role \
  --role-name AmazonEKS_EFS_CSI_DriverRole \
  --assume-role-policy-document file://"trust-policy.json"
```

### 6. Attach the IAM policy to the role

```bash
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AmazonEKS_EFS_CSI_Driver_Policy \
  --role-name AmazonEKS_EFS_CSI_DriverRole
```

---

## 🚀 Install the Amazon EFS CSI Driver

### 7. Download the manifest

```bash
kubectl kustomize "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.3" > public-ecr-driver.yaml
```

### 8. Edit the `public-ecr-driver.yaml` file

Add the following under `ServiceAccount`:

```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::<accountid>:role/AmazonEKS_EFS_CSI_DriverRole
```

### Deploy the driver

```bash
kubectl apply -f public-ecr-driver.yaml
```

> For AWS Fargate-only clusters:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/deploy/kubernetes/base/csidriver.yaml
```

---

## 🌐 Network Setup

### 9. Get VPC ID

```bash
aws eks describe-cluster --name your_cluster_name --query "cluster.resourcesVpcConfig.vpcId" --output text
```

### 10. Get VPC CIDR

```bash
aws ec2 describe-vpcs --vpc-ids YOUR_VPC_ID --query "Vpcs[].CidrBlock" --output text
```

### 11. Create a security group

```bash
aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id YOUR_VPC_ID
```

### 12. Add NFS ingress rule

```bash
aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 2049 --cidr YOUR_VPC_CIDR
```

---

## 📁 Create EFS File System

### 13. Create EFS

```bash
aws efs create-file-system --creation-token eks-efs
```

### 14. Create mount targets

```bash
aws efs create-mount-target --file-system-id FileSystemId --subnet-id SubnetID --security-group sg-xxx
```

---

## 🧪 Testing the Amazon EFS CSI Driver

### 15. Clone the repo

```bash
git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git
cd aws-efs-csi-driver/examples/kubernetes/multiple_pods/
```

### 16. Get your FileSystemId

```bash
aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text
```

### 17. Update `specs/pv.yaml` with FileSystemId

### 18. Apply Kubernetes specs

```bash
kubectl apply -f specs/
```

### 19. Verify and Test

```bash
kubectl get pv -w
kubectl describe pv efs-pv
kubectl exec -it app1 -- tail /data/out1.txt 
kubectl exec -it app2 -- tail /data/out1.txt
```

---

## ✅ Result Validation

Run:

```bash
kubectl exec -it app3 /bin/bash
kubectl exec -it app4 /bin/bash
```

> Files created in one pod are visible and editable in another pod running on a different node, validating the use of EFS for ReadWriteMany mode.

---

## 🌟 Benefits of Using EFS in Kubernetes

- **Cross-AZ Redundancy**: Scalable and HA architecture.
- **Content Management and Web Servers**: Ideal for hosting blogs, websites, and archives.
- **Dynamic Scaling**: Auto-scales with your application usage.

> 📝 For stateful applications requiring `ReadWriteMany` mode, EFS is the recommended storage over EBS.
