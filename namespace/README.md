# Kubernetes Namespaces

In **Kubernetes**, a **namespace** is a way to divide cluster resources between **multiple users or teams**. It's like a virtual cluster within a cluster — useful for organizing and managing large environments.

---

## 🧩 Why Use Namespaces?

Namespaces help you:
- **Logically separate environments** (e.g., dev, staging, prod)
- Apply **resource limits** per team/project
- **Isolate applications** for security or structure
- Manage access using **RBAC** (role-based access control)

---

## 🛠 Example Use Case

Imagine you have two teams deploying apps:
- Team A runs in namespace `team-a`
- Team B runs in namespace `team-b`

They can both create resources named `my-app` — but they won’t conflict, because they’re in different namespaces.

---

## 🔧 Common Commands

### ✅ Create a namespace
```bash
kubectl create namespace my-namespace
```

### ✅ Apply resources to a namespace
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: my-namespace
spec:
  containers:
    - name: nginx
      image: nginx
```

Or use the CLI:
```bash
kubectl apply -f pod.yaml -n my-namespace
```

### ✅ List all namespaces
```bash
kubectl get namespaces
```

### ✅ Get resources in a namespace
```bash
kubectl get pods -n my-namespace
```

---

## 📦 Default Namespaces in Kubernetes

| Namespace    | Purpose |
|--------------|---------|
| `default`    | Default for resources with no namespace |
| `kube-system` | System pods (like CoreDNS, kube-proxy) |
| `kube-public`| Public resources, readable by all |
| `kube-node-lease` | Node heartbeat tracking |

---

Want a visual example or use it with Helm, RBAC, or network policies? I can guide you on that too.


