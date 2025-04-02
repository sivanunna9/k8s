## Kubernetes Health Checks

Kubernetes provides health checks to ensure that applications are running properly.

---

### There are three main types of health checks:

#### 1️⃣ Liveness Probe (Is the container still running?)
**Purpose:** Restarts the container if it becomes unresponsive or deadlocked.

**Example:** If an application is stuck in an infinite loop, Kubernetes will kill and restart it.

**Usage:** HTTP, TCP, or Command (exec).

Example:
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 3
  periodSeconds: 5
```
- **initialDelaySeconds:** Wait time before the first check.
- **periodSeconds:** Frequency of health checks.
- **httpGet:** Calls /healthz on port 8080.

---

#### 2️⃣ Readiness Probe (Is the container ready to accept traffic?)
**Purpose:** Prevents traffic from reaching a pod that is not yet ready.

**Example:** If a database connection is not yet established, the pod remains out of service.

**Usage:** HTTP, TCP, or Command (exec).

Example:
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
```
Traffic is not sent to the pod until it responds with a 200 OK.

---

#### 3️⃣ Startup Probe (Is the application fully started?)
**Purpose:** Ensures that slow-starting applications are given enough time before liveness checks start.

**Example:** A Java application that takes a long time to initialize.

Example:
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```
- **failureThreshold: 30** → Kubernetes waits for 30 * 10s = 300s before restarting the pod.

---

## Create the Application Code

Create a directory for your app:
```sh
mkdir my-app && cd my-app
```

Create a Python Flask app file:
```sh
vi app.py
```

Paste this Flask application inside `app.py`:
```python
from flask import Flask
import time

app = Flask(__name__)

# Simulating startup delay
startup_complete = False
time.sleep(10)  # Simulate startup time
startup_complete = True

@app.route('/healthz')
def healthz():
    return "OK", 200  # Liveness probe response

@app.route('/ready')
def ready():
    if startup_complete:
        return "Ready", 200  # Readiness probe response
    return "Not Ready", 503

@app.route('/startup')
def startup():
    if startup_complete:
        return "Startup Complete", 200
    return "Still Starting", 503

@app.route('/')
def home():
    return "Hello, Kubernetes!", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

---

## 2️⃣ Create the Dockerfile

Create a Dockerfile:
```sh
vi Dockerfile
```

Paste this Dockerfile:
```dockerfile
# Use a lightweight Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY app.py /app/

# Install dependencies
RUN pip install flask

# Expose port 8080
EXPOSE 8080

# Start the Flask app
CMD ["python", "app.py"]
```

---

## 3️⃣ Build & Run the Docker Image

### Build the Docker Image
```sh
docker build -t my-app-image:v1 .
```

### Run the Container Locally
```sh
docker run -p 8080:8080 my-app-image:v1
```

---

## 4️⃣ Test the Probes Locally

Open a new terminal and run:
```sh
curl -s http://localhost:8080/healthz   # Liveness probe
curl -s http://localhost:8080/ready     # Readiness probe
curl -s http://localhost:8080/startup   # Startup probe
```

---

## ✅ Combined Example (Liveness + Readiness + Startup)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: my-app-image:v1
        ports:
        - containerPort: 8080

        # 🚀 Liveness Probe
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 3
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 3
          successThreshold: 1

        # 🚀 Readiness Probe
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
          successThreshold: 1

        # 🚀 Startup Probe
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          failureThreshold: 30
          periodSeconds: 10
          timeoutSeconds: 5
```

---

## Health Checks in Specific Use Cases

### To check if probes are passing or failing, follow these steps:

#### 1️⃣ Check Pod Status
```sh
kubectl get pods
```
Look for the `READY` column. If it's `0/1` or `0/3`, the readiness probe might be failing.

#### 2️⃣ Describe the Pod
```sh
kubectl describe pod <pod-name>
```
Check for Events:
- If **Liveness probe failed**, the container will restart.
- If **Readiness probe failed**, the pod won't receive traffic.
- If **Startup probe failed**, the container might be stuck in a crash loop.

#### 3️⃣ Check Probe Logs
```sh
kubectl logs <pod-name>
```
If the probes fail, the logs might show errors like `Timeout` or `Connection refused`.

#### 4️⃣ Debug with Exec
```sh
kubectl exec -it <pod-name> -- curl -v localhost:8080/healthz
kubectl exec -it <pod-name> -- curl -v localhost:8080/ready
kubectl exec -it <pod-name> -- curl -v localhost:8080/startup
```

#### 5️⃣ Check Restart Count
```sh
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[*].restartCount}'
```
A high restart count indicates probe failures.

#### 6️⃣ Fix Common Issues
Ensure your application correctly serves `/healthz`, `/ready`, and `/startup` on port 8080.


