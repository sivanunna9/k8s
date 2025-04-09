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
