# EKS + Solo.io Istio — Service Mesh Guide

## 1. Overview

This README explains how Istio works with an existing Amazon EKS cluster and how to understand:

* Istio architecture
* Solo.io and Istio relationship
* Control plane vs data plane
* Envoy sidecar
* Service-to-service traffic
* Traffic routing
* Canary deployments
* mTLS
* Istio Gateway
* `istiod` failure
* Envoy failure
* Troubleshooting
* Important `istioctl` commands

The goal is to understand **how traffic flows through an Istio service mesh** and how to troubleshoot it as a DevOps/SRE engineer.

---

# 2. What is Istio?

Istio is a **service mesh** used to control, secure, and observe communication between microservices.

Kubernetes already provides:

* Service discovery
* Pod networking
* Service load balancing

Istio adds capabilities such as:

* mTLS
* Traffic routing
* Canary deployments
* Retries
* Timeouts
* Circuit breaking
* Authorization
* Observability
* Service-level traffic policies

### Simple mental model

```text
Kubernetes
    |
    +-- Runs applications
    +-- Provides networking
    +-- Provides Services

Istio
    |
    +-- Controls service-to-service traffic
    +-- Secures traffic
    +-- Provides traffic policies
    +-- Provides observability
```

---

# 3. Why Do We Need Istio?

Without Istio:

```text
Frontend
    |
    | HTTP
    v
Kubernetes Service
    |
    v
Backend
```

Application teams may need to implement:

```text
TLS
Retry
Timeout
Circuit Breaker
Authentication
Traffic routing
Observability
```

With Istio:

```text
Frontend App
     |
     v
Frontend Envoy
     |
     | mTLS
     v
Backend Envoy
     |
     v
Backend App
```

The networking functionality is moved into the service mesh.

---

# 4. Istio Architecture

Istio has two major concepts:

```text
             Istio
               |
       +-------+-------+
       |               |
       v               v
 Control Plane      Data Plane
       |               |
     istiod          Envoy
                       |
                  Application
```

## Control Plane

The control plane manages configuration.

Main component:

```text
istiod
```

It provides configuration and identity/certificate information to Envoy proxies.

---

## Data Plane

The data plane handles actual application traffic.

The main component is:

```text
Envoy Proxy
```

Traffic flows through Envoy.

```text
Application
     |
     v
Envoy
     |
     | Network traffic
     v
Envoy
     |
     v
Application
```

---

# 5. Control Plane vs Data Plane

| Component          | Responsibility                       |
| ------------------ | ------------------------------------ |
| `istiod`           | Control plane                        |
| Envoy              | Data plane                           |
| VirtualService     | Traffic routing                      |
| DestinationRule    | Backend subsets/policies             |
| PeerAuthentication | mTLS policy                          |
| Gateway            | Ingress/egress traffic configuration |

### Remember

```text
istiod = tells Envoy what to do

Envoy = actually handles traffic
```

---

# 6. What is Envoy?

Envoy is a high-performance proxy.

In Istio sidecar mode, Envoy runs next to the application container.

A typical pod becomes:

```text
Pod
+-------------------------+
| Application             |
|                         |
| Envoy Sidecar           |
+-------------------------+
```

Therefore:

```text
Application
     |
     v
Envoy
     |
     v
Network
```

The receiving pod has:

```text
Network
     |
     v
Envoy
     |
     v
Application
```

---

# 7. Sidecar Injection

Istio can automatically inject Envoy into application pods.

Example:

```bash
kubectl label namespace demo istio-injection=enabled
```

After deploying an application:

```bash
kubectl get pods -n demo
```

You may see:

```text
NAME             READY
backend-xxx      2/2
```

Why `2/2`?

```text
1 = Application container

2 = Envoy sidecar
```

Check containers:

```bash
kubectl get pod <pod> -n demo \
  -o jsonpath='{.spec.containers[*].name}'
```

Expected:

```text
backend istio-proxy
```

---

# 8. Without Istio vs With Istio

## Without Istio

```text
Client
  |
  v
Kubernetes Service
  |
  v
Backend Pod
```

## With Istio

```text
Client Application
       |
       v
Client Envoy
       |
       | mTLS
       v
Backend Envoy
       |
       v
Backend Application
```

The Envoy proxies become part of the traffic path.

---

# 9. Solo.io and Istio

Solo.io is a company that provides enterprise products around cloud-native networking and technologies such as Istio.

Think of the relationship as:

```text
Istio
  |
  | Open-source service mesh
  |
  v
Solo.io
  |
  +-- Enterprise Istio offerings
  +-- Gloo Platform
  +-- Service mesh management
  +-- API Gateway capabilities
```

Istio and Solo.io are **not the same thing**.

```text
Istio     = technology/project

Solo.io   = company/vendor
```

Solo.io provides enterprise capabilities and supported distributions/platforms around technologies including Istio.

---

# 10. Existing EKS Architecture

A typical EKS + Istio architecture can look like:

```text
                         Internet
                            |
                            v
                         AWS ALB
                            |
                            v
                  Istio Ingress Gateway
                            |
                            v
                     Frontend Service
                            |
                            v
                      Frontend Envoy
                            |
                           mTLS
                            |
                            v
                       Backend Envoy
                            |
                            v
                     Backend Application
```

The Istio control plane is separate:

```text
                         istiod
                           |
              configuration/certificates
                           |
              +------------+------------+
              |                         |
              v                         v
        Frontend Envoy            Backend Envoy
```

---

# 11. Installing Solo Istio on Existing EKS

Before installation, check whether Istio already exists.

```bash
kubectl get pods -n istio-system
```

Check CRDs:

```bash
kubectl get crd | grep istio
```

Check webhooks:

```bash
kubectl get mutatingwebhookconfiguration | grep -i istio
```

Do not install another Istio control plane blindly over an existing installation.

---

# 12. High-Level Solo Installation Flow

The general installation flow is:

```text
Existing EKS
     |
     v
Install Gloo/Solo Operator
     |
     v
Create ServiceMeshController
     |
     v
Install Solo Istio
     |
     v
istiod
     |
     v
Enable namespace injection
     |
     v
Deploy application
     |
     v
Envoy sidecars
```

Solo's exact installation commands and supported versions depend on the Solo release and license being used.

---

# 13. Verify Istio Installation

Check:

```bash
kubectl get pods -n istio-system
```

Check services:

```bash
kubectl get svc -n istio-system
```

Check Istio version:

```bash
istioctl version
```

Check installation:

```bash
istioctl verify-install
```

Check proxy status:

```bash
istioctl proxy-status
```

---

# 14. Deploy Test Application

Create a test namespace:

```bash
kubectl create namespace demo
```

Enable injection:

```bash
kubectl label namespace demo istio-injection=enabled
```

Deploy application:

```text
demo namespace
     |
     +-- frontend
     |      |
     |    Envoy
     |
     +-- backend
            |
          Envoy
```

Verify:

```bash
kubectl get pods -n demo
```

Expected:

```text
frontend-xxx    2/2
backend-xxx     2/2
```

---

# 15. Service-to-Service Traffic

Without Istio:

```text
Frontend
   |
   | HTTP
   v
backend:80
   |
   v
Backend Pod
```

With Istio:

```text
Frontend App
     |
     v
Frontend Envoy
     |
     | mTLS
     v
Backend Envoy
     |
     v
Backend App
```

The application can continue to use the normal Kubernetes Service name:

```text
http://backend
```

Istio handles the mesh traffic underneath.

---

# 16. VirtualService

A `VirtualService` defines how traffic should be routed.

Example:

```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend
  http:
  - route:
    - destination:
        host: backend
        subset: v1
      weight: 90
    - destination:
        host: backend
        subset: v2
      weight: 10
```

This means:

```text
Backend Service
      |
      +---- 90% ---> v1
      |
      +---- 10% ---> v2
```

---

# 17. DestinationRule

A `DestinationRule` defines subsets.

Example:

```yaml
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: backend
spec:
  host: backend

  subsets:

  - name: v1
    labels:
      version: v1

  - name: v2
    labels:
      version: v2
```

Now Istio understands:

```text
backend
   |
   +-- v1
   |    |
   |   Pods with version=v1
   |
   +-- v2
        |
       Pods with version=v2
```

---

# 18. Canary Deployment

Istio can be used for progressive traffic shifting.

Example:

```text
Initial

v1 = 100%
v2 = 0%
```

Then:

```text
v1 = 90%
v2 = 10%
```

Then:

```text
v1 = 75%
v2 = 25%
```

Then:

```text
v1 = 50%
v2 = 50%
```

Finally:

```text
v1 = 0%
v2 = 100%
```

This allows controlled rollout.

---

# 19. mTLS

mTLS means:

```text
Mutual TLS
```

Both sides authenticate each other.

Without mTLS:

```text
Frontend
   |
   | HTTP
   v
Backend
```

With Istio mTLS:

```text
Frontend Envoy
      |
      | encrypted + authenticated
      | mTLS
      v
Backend Envoy
```

Istio manages workload identities and certificates for mesh workloads.

---

# 20. Enable STRICT mTLS

Example:

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: demo
spec:
  mtls:
    mode: STRICT
```

This means workloads in the namespace require mTLS.

Conceptually:

```text
Mesh workload
      |
      | mTLS
      v
Mesh workload

Non-mesh workload
      |
      X
```

---

# 21. Verify mTLS

Useful command:

```bash
istioctl x authn tls-check \
  <pod> \
  -n demo
```

Inspect Envoy configuration:

```bash
istioctl proxy-config clusters \
  <pod> \
  -n demo
```

Inspect certificates:

```bash
istioctl proxy-config secret \
  <pod> \
  -n demo
```

---

# 22. Istio Gateway

An Istio Gateway manages traffic entering or leaving the mesh.

Typical architecture:

```text
Internet
   |
   v
AWS ALB
   |
   v
Istio Ingress Gateway
   |
   v
VirtualService
   |
   v
Application
```

For external traffic, there can be multiple layers:

```text
Client
  |
  v
AWS ALB
  |
  v
Istio Gateway
  |
  v
Envoy
  |
  v
Application
```

---

# 23. What Happens if `istiod` Fails?

This is an important production concept.

`istiod` is the **control plane**.

Envoy is the **data plane**.

If `istiod` fails:

```text
              X
            istiod
              |
              X
              |
Existing Envoys
              |
              v
        Application traffic
```

Existing Envoy proxies generally continue using their last-known configuration.

Therefore, a temporary `istiod` failure does **not necessarily cause an immediate application outage**.

However:

* New configuration may not reach Envoy.
* Traffic-routing changes may not be applied.
* Certificate rotation can be affected.
* New workloads may have problems obtaining configuration/identity.
* A prolonged control-plane outage can eventually impact the mesh.

---

# 24. Production `istiod` HA

Do not rely on a single control-plane replica for production.

Conceptually:

```text
              istiod
          /      |      \
         /       |       \
    istiod-1  istiod-2  istiod-3
```

If one fails:

```text
istiod-1     X
istiod-2     OK
istiod-3     OK
```

The remaining control-plane replicas can continue serving the mesh.

For production, consider:

* Multiple replicas
* Node/AZ distribution
* Pod anti-affinity/topology spread
* Resource requests/limits
* Monitoring
* Alerting

---

# 25. What Happens if Envoy Fails?

This is different from `istiod`.

Envoy is in the **data path**.

Normal:

```text
Application
     |
     v
Envoy
     |
     v
Network
```

If Envoy fails:

```text
Application
     |
     X
   Envoy
```

Traffic involving that pod can fail.

Possible symptoms:

```text
503
502
504
connection reset
connection timeout
```

---

# 26. Envoy Failure With Multiple Replicas

Suppose:

```text
backend
   |
   +-- Pod A + Envoy
   +-- Pod B + Envoy
   +-- Pod C + Envoy
```

If Pod A's Envoy fails:

```text
Pod A   X
Pod B   OK
Pod C   OK
```

Traffic can continue through healthy replicas, provided Kubernetes/Istio health and readiness correctly remove the unhealthy endpoint from usable traffic.

This is why application redundancy is important.

---

# 27. Ingress Gateway Failure

External traffic is more sensitive.

Architecture:

```text
Internet
   |
   v
AWS ALB
   |
   v
Istio Gateway
```

If all gateway Envoys fail:

```text
Internet
   |
   v
AWS ALB
   |
   X
Istio Gateway
```

Clients can receive:

```text
502
503
504
```

Therefore use multiple gateway replicas:

```text
Istio Gateway
   |
   +-- Gateway Pod 1
   +-- Gateway Pod 2
   +-- Gateway Pod 3
```

---

# 28. `istiod` Failure vs Envoy Failure

| Failure           | Existing traffic                 | Configuration changes | Impact              |
| ----------------- | -------------------------------- | --------------------- | ------------------- |
| `istiod` down     | Usually continues                | Delayed/not delivered | Control plane       |
| One Envoy down    | Traffic to affected pod can fail | N/A                   | Data plane          |
| One gateway down  | Other gateways can serve         | N/A                   | Depends on replicas |
| All Envoys down   | Traffic fails                    | N/A                   | Data plane outage   |
| All gateways down | External traffic fails           | N/A                   | Ingress outage      |

### Key rule

```text
istiod failure
    =
control-plane problem

Envoy failure
    =
data-plane problem
```

---

# 29. Important `istioctl` Commands

## Check control plane

```bash
istioctl proxy-status
```

Example:

```text
NAME                  CDS    LDS    EDS    RDS
client.demo           SYNCED SYNCED SYNCED SYNCED
backend.demo          SYNCED SYNCED SYNCED SYNCED
```

---

## Analyze configuration

```bash
istioctl analyze -n demo
```

Use this early when debugging configuration problems.

---

## Routes

```bash
istioctl proxy-config routes \
  <pod> \
  -n demo
```

Shows how Envoy routes HTTP traffic.

---

## Clusters

```bash
istioctl proxy-config clusters \
  <pod> \
  -n demo
```

Shows upstream services known to Envoy.

---

## Endpoints

```bash
istioctl proxy-config endpoints \
  <pod> \
  -n demo
```

Shows actual backend endpoints.

---

## Listeners

```bash
istioctl proxy-config listeners \
  <pod> \
  -n demo
```

Shows what listeners Envoy has configured.

---

## Certificates

```bash
istioctl proxy-config secret \
  <pod> \
  -n demo
```

Useful for TLS/certificate troubleshooting.

---

# 30. Kubernetes Troubleshooting Commands

Always check Kubernetes before blaming Istio.

```bash
kubectl get pods -n demo
```

```bash
kubectl get svc -n demo
```

```bash
kubectl get endpoints -n demo
```

```bash
kubectl get endpointslices -n demo
```

```bash
kubectl describe pod <pod> -n demo
```

```bash
kubectl logs <pod> -n demo -c istio-proxy
```

Previous Envoy crash:

```bash
kubectl logs <pod> \
  -n demo \
  -c istio-proxy \
  --previous
```

Application logs:

```bash
kubectl logs <pod> \
  -n demo \
  -c <application-container>
```

---

# 31. Recommended Troubleshooting Flow

When you receive:

```text
502 / 503 / 504
```

follow this order:

```text
                Application Error
                       |
                       v
                Pod healthy?
                       |
                       v
                Service correct?
                       |
                       v
                Endpoints exist?
                       |
                       v
                EndpointSlice correct?
                       |
                       v
                Envoy healthy?
                       |
                       v
                Envoy configuration?
                       |
                       v
                VirtualService?
                       |
                       v
                DestinationRule?
                       |
                       v
                mTLS?
                       |
                       v
                Istio Gateway?
                       |
                       v
                AWS ALB?
```

Useful commands:

```bash
kubectl get pods -n demo
kubectl get svc -n demo
kubectl get endpoints -n demo
kubectl get endpointslices -n demo

kubectl get virtualservice -n demo
kubectl get destinationrule -n demo
kubectl get peerauthentication -n demo

istioctl analyze -n demo
istioctl proxy-status
```

---

# 32. Envoy Admin Interface

Envoy provides an admin interface, commonly on port:

```text
15000
```

Useful endpoints include:

```text
/stats
/clusters
/listeners
/config_dump
/server_info
```

Example:

```bash
kubectl exec \
  -n demo \
  <pod> \
  -c istio-proxy \
  -- curl -s http://127.0.0.1:15000/clusters
```

This is useful for deep Envoy troubleshooting.

---

# 33. End-to-End Traffic Flow

The most important architecture to remember:

```text
                         Internet
                            |
                            v
                         AWS ALB
                            |
                            v
                  Istio Ingress Gateway
                            |
                            v
                       Envoy Proxy
                            |
                            v
                     VirtualService
                            |
                  +---------+---------+
                  |                   |
                90%                 10%
                  |                   |
                  v                   v
             Backend v1          Backend v2
                  |                   |
                Envoy               Envoy
                  |                   |
                  +--------mTLS-------+
                            |
                       Application
```

Control plane:

```text
                       istiod
                      /      \
                     /        \
                    v          v
             Gateway Envoy   App Envoy
```

---

# 34. High-Level Failure Scenarios

## Scenario 1 — `istiod` fails

```text
istiod
  X

Existing Envoy
    |
    v
Existing configuration
    |
    v
Traffic generally continues
```

Main impact:

```text
Configuration
Certificates
New workloads
Control-plane operations
```

---

## Scenario 2 — One application Envoy fails

```text
Pod A
  Envoy X

Pod B
  Envoy OK

Pod C
  Envoy OK
```

Traffic can continue through healthy replicas.

---

## Scenario 3 — All application Envoys fail

```text
Backend
  |
  +-- Envoy X
  +-- Envoy X
  +-- Envoy X
```

Traffic fails.

---

## Scenario 4 — One Gateway fails

```text
Gateway 1  X
Gateway 2  OK
Gateway 3  OK
```

External traffic can continue through healthy gateways.

---

## Scenario 5 — All Gateways fail

```text
AWS ALB
   |
   X
Istio Gateway
```

External client traffic fails.

---

# 35. Production High Availability

A production EKS + Istio architecture should consider:

```text
                    AWS ALB
                       |
              +--------+--------+
              |        |        |
              v        v        v
           Gateway  Gateway  Gateway
              |        |        |
              +--------+--------+
                       |
                    Services
                       |
             +---------+---------+
             |                   |
          Backend              Backend
           Pod A                Pod B
          +Envoy               +Envoy
```

Control plane:

```text
             istiod
           /    |    \
          /     |     \
       AZ-1    AZ-2    AZ-3
```

Important production considerations:

* Multiple `istiod` replicas
* Multiple ingress gateway replicas
* Application replicas
* PodDisruptionBudgets
* Topology spread
* Readiness/liveness probes
* Resource requests and limits
* Monitoring
* Alerting
* Certificate monitoring
* AWS ALB health checks
* Prometheus/Grafana
* Centralized logging

---

# 36. Important Mental Model

Remember these five components:

```text
Kubernetes
    |
    | runs
    v
Application


Istio
    |
    | manages mesh
    v
istiod


Envoy
    |
    | handles traffic
    v
Application communication


VirtualService
    |
    | decides routing
    v
v1 / v2


PeerAuthentication
    |
    | controls mTLS
    v
Secure communication
```

---

# 37. Interview Cheat Sheet

### What is Istio?

> Istio is a service mesh that provides traffic management, security, and observability for microservices.

### What is Envoy?

> Envoy is the data-plane proxy that handles application traffic.

### What is `istiod`?

> `istiod` is the Istio control-plane component responsible for distributing configuration and workload identity/certificate information to proxies.

### Why do we need Istio if Kubernetes already has Services?

> Kubernetes provides basic service discovery and load balancing. Istio adds advanced traffic management, mTLS, authorization, retries, timeouts, and observability.

### What is VirtualService?

> VirtualService defines how traffic should be routed to services or service subsets.

### What is DestinationRule?

> DestinationRule defines service subsets and traffic policies such as connection pools, load balancing, and outlier detection.

### What is mTLS?

> Mutual TLS encrypts traffic and authenticates both sides of service-to-service communication.

### What happens if `istiod` fails?

> Existing Envoy proxies generally continue using their last-known configuration, but configuration updates, certificate rotation, and new workload configuration can be affected.

### What happens if Envoy fails?

> Envoy is part of the data path, so traffic involving that pod can fail. Multiple healthy replicas allow traffic to continue through other pods.

### How do you troubleshoot Istio?

```bash
istioctl analyze
istioctl proxy-status
istioctl proxy-config routes
istioctl proxy-config clusters
istioctl proxy-config endpoints
kubectl logs -c istio-proxy
kubectl get endpointslices
```

---

# 38. Final Architecture to Remember

```text
                         ┌─────────────────┐
                         │     Internet    │
                         └────────┬────────┘
                                  |
                                  v
                         ┌─────────────────┐
                         │    AWS ALB      │
                         └────────┬────────┘
                                  |
                                  v
                    ┌─────────────────────────┐
                    │ Istio Ingress Gateway   │
                    │        Envoy            │
                    └───────────┬─────────────┘
                                |
                                v
                       ┌─────────────────┐
                       │ VirtualService  │
                       └────────┬────────┘
                                |
                   ┌────────────┴────────────┐
                   |                         |
                 90%                       10%
                   |                         |
                   v                         v
          ┌─────────────────┐       ┌─────────────────┐
          │ Backend v1      │       │ Backend v2      │
          │                 │       │                 │
          │ Application     │       │ Application     │
          │ + Envoy         │       │ + Envoy         │
          └─────────────────┘       └─────────────────┘
                   |                         |
                   +-----------mTLS----------+

                         CONTROL PLANE
                              |
                              v
                         ┌─────────┐
                         │ istiod  │
                         └────┬────┘
                              |
                 configuration / certificates
                              |
                ┌─────────────┴─────────────┐
                |                           |
             Envoy                       Envoy
```

## The most important takeaway

```text
                    ISTIO
                      |
          +-----------+-----------+
          |                       |
     CONTROL PLANE            DATA PLANE
          |                       |
       istiod                   Envoy
          |                       |
    tells Envoy how          handles actual
    to behave                application traffic
```

**`istiod` failure → primarily control-plane impact.**

**Envoy failure → directly affects data-plane traffic.**

**Multiple replicas → provide resilience.**

**VirtualService → controls traffic routing.**

**DestinationRule → defines subsets/policies.**

**PeerAuthentication → controls mTLS.**

**AWS ALB + Istio Gateway → handles external traffic into the mesh.**
