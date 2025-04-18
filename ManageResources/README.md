# 🚀 Kubernetes Resource Management – Complete Guide with Examples

Managing resources effectively in Kubernetes is crucial for performance, cost efficiency, and cluster stability. This documentation covers everything you need to get started with CPU and memory resource requests, limits, quotas, and monitoring strategies in Kubernetes – particularly useful for EKS and cloud-native environments.

---

## 📘 Table of Contents

- [Introduction](#introduction)
- [Resource Requests and Limits](#resource-requests-and-limits)
- [Why Resource Limits Matter](#why-resource-limits-matter)
- [Defining Resources: Pod Example](#defining-resources-pod-example)
- [ResourceQuota Example](#resourcequota-example)
- [LimitRange Example](#limitrange-example)
- [Step-by-Step Guide](#step-by-step-guide)
- [Monitoring Resource Usage](#monitoring-resource-usage)
- [Best Practices](#best-practices)
- [Additional Features in Kubernetes](#additional-features-in-kubernetes)
- [References](#references)

---

## 🧠 Introduction

Kubernetes allows developers and platform engineers to define how containers consume cluster resources. By defining **resource requests** and **limits**, you can:

- Ensure predictable performance.
- Prevent overcommitment or starvation.
- Enable efficient autoscaling.
- Maintain high availability and cost control.

---

## ⚙️ Resource Requests and Limits

| Type       | Description                                                                 |
|------------|-----------------------------------------------------------------------------|
| `requests` | Minimum guaranteed resources a container needs. Used for pod scheduling.   |
| `limits`   | Maximum resources a container can use. Enforced during runtime.            |

- CPU is measured in millicores (`1000m = 1 CPU`)
- Memory is measured in Mi or Gi (`128Mi`, `2Gi`)

---

## ❓ Why Resource Limits Matter

- 🔒 Prevents containers from exhausting node resources
- 🚫 Avoids Out-of-Memory (OOM) kills
- 📊 Helps Kubernetes schedule more efficiently
- 💵 Reduces cloud waste (especially on AWS EKS)
- 🔄 Required for auto-scaling features (HPA, VPA)

---

## ✍️ Defining Resources: Pod Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
    - name: nginx
      image: nginx
      resources:
        requests:
          memory: "64Mi"
          cpu: "250m"
        limits:
          memory: "128Mi"
          cpu: "500m"
```

This ensures the container will get **at least 64Mi and 250m CPU**, and cannot exceed **128Mi and 500m CPU**.

---

## 📦 ResourceQuota Example

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
  namespace: dev-team
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
```

**Purpose**: Limits total CPU/memory requests and limits for all pods in `dev-team` namespace.

---

## 📏 LimitRange Example

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
  namespace: dev-team
spec:
  limits:
    - type: Container
      default:
        cpu: 500m
        memory: 512Mi
      defaultRequest:
        cpu: 200m
        memory: 256Mi
      max:
        cpu: 1
        memory: 1Gi
      min:
        cpu: 100m
        memory: 128Mi
```

**Purpose**:
- Applies default requests/limits when none are set.
- Ensures containers don’t exceed defined min/max resource bounds.

---

## 🛠 Step-by-Step Guide

### 1. Create Namespace

```bash
kubectl create namespace dev-team
```

### 2. Apply Quotas and Limits

```bash
kubectl apply -f resource-quota.yaml
kubectl apply -f limit-range.yaml
```

### 3. Deploy Resource-Managed Pod

```bash
kubectl apply -f resource-demo.yaml
```

### 4. Verify

```bash
kubectl describe pod resource-demo -n dev-team
kubectl top pod -n dev-team
```

---

## 📈 Monitoring Resource Usage

### Enable Metrics Server (if not already installed)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Commands to Monitor

```bash
kubectl top pod
kubectl top node
```

### Recommended Tools

- **Prometheus + Grafana** – Open-source metrics stack
- **AWS CloudWatch Container Insights** – Built-in for EKS
- **Kubecost** – Cost monitoring and resource optimization
- **Datadog, New Relic, Sysdig** – Commercial APM tools

---

## ✅ Best Practices

| 🧠 Tip | ✅ Recommendation |
|-------|-------------------|
| Understand workload | Benchmark app to estimate CPU/memory usage. |
| Avoid no limits | Always define both `requests` and `limits`. |
| Use `LimitRange` | Set defaults in each namespace to enforce policies. |
| Use `ResourceQuota` | Prevent namespace abuse in shared environments. |
| Combine with HPA/VPA | Use autoscaling for dynamic load handling. |
| Monitor continuously | Track actual usage to optimize over time. |

---

## 🧰 Additional Features in Kubernetes

| Feature | Description |
|--------|-------------|
| **ResourceQuota** | Caps total resource usage per namespace. |
| **LimitRange** | Sets default/min/max resource policies. |
| **HPA (Horizontal Pod Autoscaler)** | Scales pod count based on metrics. |
| **VPA (Vertical Pod Autoscaler)** | Adjusts resource requests dynamically. |
| **Karpenter (EKS)** | Advanced autoscaler that launches optimized EC2 nodes. |

---

