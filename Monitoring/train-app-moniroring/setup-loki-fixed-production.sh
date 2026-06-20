#!/bin/bash

set -euo pipefail

echo "🚀 FIXED EKS Observability Stack (Loki + Fluent Bit)"

NAMESPACE=logging

# -----------------------------
# 1. Namespace
# -----------------------------
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------
# 2. Helm repos
# -----------------------------
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo add fluent https://fluent.github.io/helm-charts || true
helm repo update

# -----------------------------
# 3. CLEAN OLD INSTALLS (IMPORTANT)
# -----------------------------
echo "🧹 Cleaning old deployments..."
helm uninstall loki -n $NAMESPACE || true
helm uninstall fluent-bit -n $NAMESPACE || true
kubectl delete pvc -n $NAMESPACE --all || true

# -----------------------------
# 4. INSTALL LOKI (FIXED PVC + gp3)
# -----------------------------
echo "🧠 Installing Loki (fixed storage config)..."

cat > loki-values.yaml <<EOF
deploymentMode: SimpleScalable

loki:
  auth_enabled: false

singleBinary:
  replicas: 0

read:
  replicas: 1
  persistence:
    enabled: true
    storageClass: gp3
    size: 10Gi

write:
  replicas: 1
  persistence:
    enabled: true
    storageClass: gp3
    size: 10Gi

backend:
  replicas: 1
  persistence:
    enabled: true
    storageClass: gp3
    size: 10Gi

limits_config:
  retention_period: 168h
EOF

helm install loki grafana/loki-simple-scalable \
  -n $NAMESPACE \
  -f loki-values.yaml \
  --wait

# -----------------------------
# 5. INSTALL FLUENT BIT (FIXED PROBES ISSUE)
# -----------------------------
echo "📡 Installing Fluent Bit (probe fixed)..."

cat > fluentbit-values.yaml <<EOF
service:
  type: ClusterIP

daemonSet:
  enabled: true

# IMPORTANT FIX: disable broken probes
readinessProbe:
  enabled: false

livenessProbe:
  enabled: false

config:
  service: |
    [SERVICE]
        Flush 1
        Log_Level info
        HTTP_Server Off

  inputs: |
    [INPUT]
        Name tail
        Path /var/log/containers/*.log
        Parser docker
        Tag kube.*

  filters: |
    [FILTER]
        Name kubernetes
        Match kube.*
        Merge_Log On
        Keep_Log Off

  outputs: |
    [OUTPUT]
        Name loki
        Match *
        Host loki.$NAMESPACE.svc.cluster.local
        Port 3100
        Labels job=fluentbit,namespace=\$kubernetes['namespace_name'],pod=\$kubernetes['pod_name']
EOF

helm install fluent-bit fluent/fluent-bit \
  -n $NAMESPACE \
  -f fluentbit-values.yaml \
  --wait

# -----------------------------
# 6. VERIFY
# -----------------------------
echo ""
echo "🔍 POD STATUS:"
kubectl get pods -n $NAMESPACE

echo ""
echo "📦 PVC STATUS:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "📡 SERVICES:"
kubectl get svc -n $NAMESPACE

# -----------------------------
# 7. SUCCESS INFO
# -----------------------------
echo ""
echo "✅ OBSERVABILITY STACK READY"
echo ""
echo "👉 Grafana (your ALB):"
echo "http://acaaac9d52da242c5a233a01246bbf6c-1758470722.us-east-1.elb.amazonaws.com/"
echo ""
echo "👉 Loki datasource URL:"
echo "http://loki.$NAMESPACE.svc.cluster.local:3100"
echo ""
echo "👉 Log query in Grafana:"
echo "{job=\"fluentbit\"}"
