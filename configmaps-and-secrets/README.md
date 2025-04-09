# Kubernetes ConfigMaps & Secrets with Examples

ConfigMaps store non-sensitive configuration data, while Secrets store sensitive data like passwords or API keys.

## 1️⃣ ConfigMap (Stores Non-Sensitive Configuration)
A ConfigMap holds plain text configuration values that pods can access as environment variables or mounted files.

### Example: ConfigMap YAML
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configmap
data:
  APP_ENV: "production"
  DB_HOST: "mysql-service"
  DB_PORT: "3306"
```

### How to Use ConfigMap in a Pod
#### As Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-container
      image: nginx
      env:
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: my-configmap
              key: APP_ENV
```

#### As Mounted Files
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-container
      image: nginx
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: my-configmap
```

---

## 2️⃣ Secret (Stores Sensitive Data)
A Secret is similar to a ConfigMap but stores base64-encoded sensitive data like passwords.

### Example: Secret YAML
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQ=  # "password" encoded in base64
```

### How to Encode Secret Data
```sh
echo -n "password" | base64
```

### How to Use Secret in a Pod
#### As Environment Variables
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-container
      image: nginx
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-secret
              key: DB_PASSWORD
```

#### As Mounted Files
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: my-container
      image: nginx
      volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets
  volumes:
    - name: secret-volume
      secret:
        secretName: my-secret
```

---

## 3️⃣ Creating ConfigMaps & Secrets via CLI
### Create ConfigMap from CLI
```sh
kubectl create configmap my-configmap --from-literal=APP_ENV=production --from-literal=DB_HOST=mysql-service
```

### Create Secret from CLI
```sh
kubectl create secret generic my-secret --from-literal=DB_PASSWORD=password
```

### Check Created ConfigMaps & Secrets
```sh
kubectl get configmaps
kubectl get secrets
kubectl describe secret my-secret
```

---

## Summary Table
| Feature               | ConfigMap | Secret |
|----------------------|-----------|--------|
| Stores Sensitive Data? | ❌ No     | ✅ Yes |
| Data Encoding         | Plain Text | Base64 |
| Example Usage        | App settings, URLs | Passwords, API keys |


