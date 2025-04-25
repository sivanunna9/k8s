
# Canary Deployment on AWS EKS (with Blue Deployment)

## Step-by-Step Guide

This guide demonstrates how to perform a Canary deployment in Kubernetes on AWS EKS, starting with a Blue deployment, followed by a gradual rollout of the Green (Canary) version.

---

## 1. Prepare Docker Images

### Dockerfile for Blue Version
```Dockerfile
FROM nginx:alpine
COPY blue.html /usr/share/nginx/html/index.html
```

### Dockerfile for Green Version
```Dockerfile
FROM nginx:alpine
COPY green.html /usr/share/nginx/html/index.html
```

### HTML Files
**blue.html**
```html
<html><body style="background-color:blue;color:white;text-align:center;"><h1>This is the BLUE version</h1></body></html>
```

**green.html**
```html
<html><body style="background-color:green;color:white;text-align:center;"><h1>This is the GREEN version</h1></body></html>
```

### Build and Push Images
```bash
docker build -f Dockerfile.blue -t your-dockerhub-username/myapp:blue .
docker push your-dockerhub-username/myapp:blue

docker build -f Dockerfile.green -t your-dockerhub-username/myapp:green .
docker push your-dockerhub-username/myapp:green
```

---

## 2. Deploy Blue Version

### myapp-blue-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: myapp
        image: your-dockerhub-username/myapp:blue
        ports:
        - containerPort: 80
```

### Apply Blue Deployment
```bash
kubectl apply -f myapp-blue-deployment.yaml
```

---

## 3. Create Service

### myapp-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

```bash
kubectl apply -f myapp-service.yaml
kubectl get svc myapp-service
```

---

## 4. Deploy Canary (Green) Version

### myapp-canary-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: myapp
        image: your-dockerhub-username/myapp:green
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f myapp-canary-deployment.yaml
```

### Update Service to Match All Versions
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

```bash
kubectl apply -f myapp-service.yaml
```

---

## 5. Gradual Traffic Shift

### Scale Canary Up
```bash
kubectl scale deployment myapp-canary --replicas=3
```

### Scale Blue Down
```bash
kubectl scale deployment myapp-blue --replicas=2
```

---

## 6. Full Rollout or Rollback

### Full Rollout
```bash
kubectl scale deployment myapp-canary --replicas=6
kubectl scale deployment myapp-blue --replicas=0
```

### Rollback
```bash
kubectl scale deployment myapp-canary --replicas=0
kubectl scale deployment myapp-blue --replicas=3
```

---

## 7. Access the Application

```bash
kubectl get svc myapp-service
```

Visit: `http://<EXTERNAL-IP>` in your browser.

---

## Summary

- **Behavior**: Start with Blue, test Canary (Green), then shift traffic gradually.
- **Use Case**: Safer upgrades, risk-free rollbacks, live testing with real traffic.
