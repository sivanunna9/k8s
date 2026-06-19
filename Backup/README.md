# Velero Restore Rollback Guide

Velero restore does not have an **undo** button.

A restore creates Kubernetes objects:

- Pods
- PVCs
- Services
- Deployments
- StatefulSets
- ConfigMaps
- Secrets

To undo a restore, delete the objects created by that restore.

---

## 1. Check Restore Status

List restores:

```bash
velero restore get
```

Example:

```text
NAME        BACKUP        STATUS
restore1    demo-backup   Completed
```

---

## 2. Describe Restore Details

Check what was restored:

```bash
velero restore describe restore1
```

Detailed output:

```bash
velero restore describe restore1 --details
```

---

# Option 1: Delete Everything Created By Restore (Recommended)

Velero adds restore labels to restored resources.

Delete restored workloads:

```bash
kubectl delete all \
  -A \
  -l velero.io/restore-name=restore1
```

---

## Delete PVCs

Remove restored PersistentVolumeClaims:

```bash
kubectl delete pvc \
  -A \
  -l velero.io/restore-name=restore1
```

---

## Delete ConfigMaps and Secrets

```bash
kubectl delete configmap,secret \
  -A \
  -l velero.io/restore-name=restore1
```

---

# Option 2: Delete Namespace Restore

If restore was done into a separate namespace:

Example:

```bash
kubectl delete namespace train-app
```

or:

```bash
kubectl delete namespace default
```

> Warning:
>
> Deleting a namespace removes all resources inside it.

---

# Option 3: Remove Restored Oracle StatefulSet

For Oracle StatefulSet restore:

Check resources:

```bash
kubectl get statefulset

kubectl get pvc
```

Delete StatefulSet:

```bash
kubectl delete statefulset oracle-db
```

Delete Oracle PVC:

```bash
kubectl delete pvc oracle-data-oracle-db-0
```

EBS volume deletion depends on StorageClass reclaim policy.

Example:

```bash
kubectl get storageclass
```

If reclaim policy is:

```
Delete
```

EBS volume will be removed.

If:

```
Retain
```

EBS volume remains.

---

# Check What Restore Created

Show restore resources:

```bash
velero restore describe restore1 --details
```

---

# Safer Restore Testing

For testing, restore into a different namespace.

Example:

```bash
velero restore create restore-test \
  --from-backup demo-backup \
  --namespace-mappings default:test-restore
```

Check:

```bash
kubectl get all -n test-restore
```

Rollback:

```bash
kubectl delete namespace test-restore
```

---

# Recommended for EKS + Oracle

For EKS StatefulSet workloads:

```
Velero Backup
       |
       |
       v
Namespace Restore
       |
       |
       v
Test Namespace
       |
       |
Delete Namespace
```

This is the safest restore testing method because the original application is not touched.
