
# Kubernetes Ingress Controller

The **Kubernetes Ingress Controller** is a component that manages external access to services within a Kubernetes cluster, typically via **HTTP** and **HTTPS** protocols. It acts as a **reverse proxy** and **load balancer**, enabling routing of incoming traffic based on predefined rules.

---

## 🔑 Key Features

- **Routing Rules**: Directs incoming traffic to specific services or microservices within the cluster.
- **Single Entry Point**: Centralizes external access, reducing the need for multiple load balancers.
- **Load Balancing**: Ensures high availability by distributing traffic across multiple backend services.
- **Security Enhancements**: Supports SSL/TLS termination, authentication, and WAF integration.
- **Virtual Hosting**: Enables name-based hosting to serve multiple apps under a single IP.

---

## ⚙️ How It Works

- **Ingress API Object**: Defines routing rules (host, path, backend) for external services.
- **Ingress Controller**: Implements the API object using tools like NGINX or Traefik.
- **Traffic Management**: Routes requests based on rules to appropriate services.

---

## ✅ Benefits

- Simplifies routing configuration.
- Reduces the attack surface by limiting direct exposure.
- Enables advanced features like TLS, URL rewriting, and observability tools.

Popular ingress controllers include:
- [NGINX](https://kubernetes.github.io/ingress-nginx/)
- [Traefik](https://doc.traefik.io/traefik/)
- [HAProxy](https://www.haproxy.org/)

---

## 🚀 How to Set Up

### 1. Add HELM Repository

```bash
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
```

### 2. Install the NGINX Ingress Controller

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### 3. Verify Installation

Check if the controller pod is running:

```bash
kubectl get pods -n ingress-nginx
```

Example output:

```
NAME                                        READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-89758f7c6-swwpf    1/1     Running   0          1m
```

Check if LoadBalancer is set:

```bash
kubectl get services -n ingress-nginx
```

Example output:

```
NAME                         TYPE           CLUSTER-IP     EXTERNAL-IP                                                               PORT(S)                      AGE
ingress-nginx-controller     LoadBalancer   10.100.20.84   a4217761afdb3457683821e38a3d3de7-XXXXXXXXX.us-east-2.elb.amazonaws.com   80:31105/TCP,443:31746/TCP   3d18h
```

> 📌 Note the **EXTERNAL-IP**, it will be used to map your domain to the LoadBalancer.

---

## 📦 Deploy Example Pods

```bash
kubectl apply -f https://raw.githubusercontent.com/ducks23/ingress-controller/main/deployments/deployment-foo.yaml
kubectl apply -f https://raw.githubusercontent.com/ducks23/ingress-controller/main/deployments/deployment-bar.yaml
```

---

## 🌐 Deploy Ingress Resource

```bash
kubectl apply -f ./deployments/ingress.yaml
```

After deployment, your services will be accessible at:

- `https://load-balancer.com/foo`
- `https://load-balancer.com/bar`

---

## 🧹 Clean Up

```bash
eksctl delete cluster demo
```
