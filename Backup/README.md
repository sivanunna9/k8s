Velero restore does not have an "undo" button. A restore creates Kubernetes objects (Pods, PVCs, Services, StatefulSets, etc.). To undo a restore, you delete the objects that were created by that restore.

First check the restore:

velero restore get

Example:

NAME       BACKUP        STATUS
restore1   demo-backup   Completed

Describe it:

velero restore describe restore1
Option 1: Delete everything created by that restore (recommended)

Velero adds labels to restored resources. Delete by restore label:

kubectl delete all \
  -A \
  -l velero.io/restore-name=restore1

Delete PVCs also:

kubectl delete pvc \
  -A \
  -l velero.io/restore-name=restore1

Delete ConfigMaps/Secrets:

kubectl delete configmap,secret \
  -A \
  -l velero.io/restore-name=restore1
Option 2: Delete a specific namespace restore

Example: restore was for your app namespace:

kubectl delete namespace train-app

or:

kubectl delete namespace default

(be careful, this removes everything in that namespace)

Option 3: If it restored Oracle StatefulSet

Check:

kubectl get statefulset
kubectl get pvc

Delete:

kubectl delete statefulset oracle-db

kubectl delete pvc oracle-data-oracle-db-0

EBS volume will delete according to StorageClass reclaim policy.

Check what restore created
velero restore describe restore1 --details
For future safer testing

Restore into a different namespace:

velero restore create restore-test \
  --from-backup demo-backup \
  --namespace-mappings default:test-restore

Then rollback is easy:

kubectl delete namespace test-restore

For EKS + Oracle StatefulSet, this namespace restore method is the safest.
