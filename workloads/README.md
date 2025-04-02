## Kubernetes Workload Types

### 1️⃣ ReplicaSet (Ensures a Fixed Number of Pod Replicas)
A ReplicaSet maintains a stable number of replicas.

#### Key Features:
📌 Ensures a specified number of pod replicas are always running.
📌 Automatically replaces failed pods but does not support rolling updates.
📌 Typically used as part of a Deployment.

#### Example:
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f replicaset.yaml
kubectl get pods
```

---

### 2️⃣ ReplicationController (Older Alternative to ReplicaSet)
Similar to a ReplicaSet, but now replaced by Deployments.

#### Example:
```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx-replicationcontroller
spec:
  replicas: 2
  selector:
    app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f replicationcontroller.yaml
kubectl get rc
```

---

### 3️⃣ Deployment (Manages ReplicaSets & Provides Rollbacks)
A Deployment is the most common workload type.

#### Key Features:
📌 Manages ReplicaSets and provides rolling updates.
📌 Supports rollback in case of failures.
📌 Can scale up/down easily.

#### Example:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f deployment.yaml
kubectl rollout status deployment nginx-deployment
```

---

### 4️⃣ DaemonSet (Runs One Pod Per Node)
A DaemonSet ensures each Kubernetes node runs exactly one instance of the pod (useful for monitoring/logging).

#### Key Features:
📌 Ensures one pod per node (or per selected nodes).
📌 Used for logging, monitoring, or networking agents.
📌 Pods are automatically added to new nodes in the cluster.

#### Example:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-daemonset
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f daemonset.yaml
kubectl get daemonset
```

---

### 5️⃣ Job (Runs a Pod to Completion)
A Job runs a one-time task and exits after completion.

#### Example:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: nginx-job
spec:
  completions: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      restartPolicy: Never
      containers:
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f job.yaml
kubectl get jobs
```

---

### 6️⃣ CronJob (Runs Jobs on a Schedule)
A CronJob runs Jobs on a scheduled basis, similar to Linux crontabs.

#### Example:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nginx-cronjob
spec:
  schedule: "*/5 * * * *"  # Runs every 5 minutes
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: nginx
        spec:
          restartPolicy: Never
          containers:
            - name: nginx
              image: nginx:latest
              ports:
                - containerPort: 80
              livenessProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 5
                periodSeconds: 10
```
#### Apply & Test:
```sh
kubectl apply -f cronjob.yaml
kubectl get cronjobs
```

---

### Summary Table
| Type                | Purpose                                       |
|---------------------|-----------------------------------------------|
| **ReplicaSet**      | Maintains a fixed number of pods              |
| **ReplicationController** | Older version of ReplicaSet          |
| **Deployment**      | Manages rolling updates & rollbacks           |
| **DaemonSet**      | Ensures one pod per node (e.g., logging, monitoring) |
| **Job**            | Runs once and exits                            |
| **CronJob**        | Runs jobs on a schedule                        |


