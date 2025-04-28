
# Deploying MyApp (Blue Version) using Helm and ArgoCD

This guide will walk you through installing **ArgoCD**, creating a **Helm chart** for deploying **MyApp (Blue version)**, and then using **ArgoCD** to deploy it.

## 1. Prerequisites

- **Kubernetes Cluster** (EKS, GKE, or any managed Kubernetes)
- **Helm 3+** installed
- **ArgoCD** installed and running
- A **Docker image** of `your-dockerhub-username/myapp:blue`

## 2. Install ArgoCD using Helm

### Step 1: Add the ArgoCD Helm repository

Add the official ArgoCD Helm chart repository:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### Step 2: Create a namespace for ArgoCD

Create the `argocd` namespace:

```bash
kubectl create namespace argocd
```

### Step 3: Install ArgoCD using Helm

Install ArgoCD into the `argocd` namespace:

```bash
helm install argocd argo/argo-cd --namespace argocd
```

### Step 4: Access ArgoCD UI

Expose the ArgoCD API server using `kubectl port-forward` for local access:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
or 
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc -n argocd

Use the EXTERNAL-IP / URL in your browser:

```

You can now access ArgoCD at `http://localhost:8080`.

### Step 5: Get the ArgoCD Admin password

To retrieve the admin password, run the following command:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

- **Username**: `admin`
- **Password**: (use the decoded password from above)

---

## 3. Create Helm Chart for MyApp

### Step 1: Create the Helm chart

Create a Helm chart using the following command:

```bash
helm create myapp
```

### Step 2: Clean up the generated files

You can delete unnecessary files and keep the following structure:

```
myapp/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    └── service.yaml
```

### Step 3: Edit the Helm Chart

#### 1. `Chart.yaml`

```yaml
apiVersion: v2
name: myapp
description: A Helm chart for myapp (blue version)
version: 0.1.0
appVersion: "1.0"
```

#### 2. `values.yaml`

```yaml
replicaCount: 3

image:
  repository: your-dockerhub-username/myapp
  tag: blue
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80

app:
  name: myapp
  version: blue
```

#### 3. `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}-{{ .Values.app.version }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
      version: {{ .Values.app.version }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
        version: {{ .Values.app.version }}
    spec:
      containers:
      - name: {{ .Values.app.name }}
        image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
```

#### 4. `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}-service
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ .Values.app.name }}
    version: {{ .Values.app.version }}
  ports:
  - protocol: TCP
    port: {{ .Values.service.port }}
    targetPort: 80
```

## 4. Push Helm Chart to GitHub

Push the `myapp/` directory to your GitHub repository.

```bash
git add myapp/
git commit -m "Add Helm chart for myapp blue version"
git push origin main
```

## 5. Create ArgoCD Application for MyApp

### Step 1: Create ArgoCD `Application` manifest

Create a file `myapp-application.yaml` with the following content:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-github-username/your-repo.git
    targetRevision: HEAD
    path: myapp   # Path to the Helm chart in the repo
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step 2: Apply the ArgoCD Application

Create the `myapp` namespace (if not already created) and apply the ArgoCD application manifest:

```bash
kubectl create namespace myapp
kubectl apply -f myapp-application.yaml
```

## 6. Access the MyApp Service

- After ArgoCD syncs the Helm chart, it will deploy the **MyApp (Blue version)** to the `myapp` namespace.
- The **LoadBalancer** service will be exposed with an **external IP**.

To check the service status:

```bash
kubectl get svc -n myapp
```

You should see something like:

```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)        AGE
myapp-service       LoadBalancer   10.100.2.175    a1b2c3d4e5f6.elb.amazonaws.com   80:32478/TCP   10m
```

Now, you can access the app using the **EXTERNAL-IP**:

```bash
http://<external-ip>
```

## 7. Conclusion

- **ArgoCD** was installed using **Helm**.
- A **Helm chart** for **MyApp (Blue version)** was created and deployed via ArgoCD.
- The **LoadBalancer** service exposes the app to the internet, and you can access it via the provided **EXTERNAL-IP**.

---

