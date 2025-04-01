Setup Kubernetes Dashboard in EKS
**********************************

Step 1: Deploy Kubernetes Dashboard
```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```
✅ Effect: Installs the official Kubernetes Dashboard.

Step 2: Create Admin User for Dashboard
👉 admin-user.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin-user
    namespace: kubernetes-dashboard
```

```sh
kubectl apply -f admin-user.yaml
```
✅ Effect: Creates an admin user with full access to Kubernetes.

### Using a LoadBalancer
If your EKS cluster is using AWS ALB (Application Load Balancer) or NLB (Network Load Balancer), expose the dashboard using a LoadBalancer:

```sh
kubectl get svc -n kubernetes-dashboard
```

Change the Service Type to LoadBalancer:
```sh
kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
```

Get the LoadBalancer URL:
Example output:
```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
kubernetes-dashboard   LoadBalancer   10.100.200.50   abcd-1234.elb.amazonaws.com   443:32443/TCP   5m
```

Access the Dashboard:
```
https://abcd-1234.elb.amazonaws.com
```

Step 3: Get Authentication Token
```sh
kubectl -n kubernetes-dashboard create token admin-user
```
✅ Effect: Generates a token for login.


