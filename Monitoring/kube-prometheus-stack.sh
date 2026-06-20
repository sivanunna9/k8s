#!/bin/bash

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

NAMESPACE="monitoring"
RELEASE_NAME="monitoring"

PROM_RETENTION="30d"
PROM_STORAGE="30Gi"

GRAFANA_STORAGE="20Gi"

# ============================================================================
# Validation
# ============================================================================

echo "Checking cluster access..."

kubectl cluster-info >/dev/null

echo "Connected to cluster:"
kubectl config current-context

# ============================================================================
# Namespace
# ============================================================================

kubectl get ns ${NAMESPACE} >/dev/null 2>&1 || \
kubectl create namespace ${NAMESPACE}

# ============================================================================
# Helm Repository
# ============================================================================

helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts || true

helm repo update

# ============================================================================
# Values File
# ============================================================================

cat > monitoring-values.yaml <<EOF
grafana:
  adminPassword: "ChangeThisImmediately123!"

  persistence:
    enabled: true
    type: pvc
    storageClassName: gp3
    accessModes:
      - ReadWriteOnce
    size: ${GRAFANA_STORAGE}

  service:
    type: LoadBalancer

  defaultDashboardsEnabled: true

prometheus:
  service:
    type: ClusterIP

  prometheusSpec:
    retention: ${PROM_RETENTION}

    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: ${PROM_STORAGE}

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 20Gi

kube-state-metrics:
  enabled: true

nodeExporter:
  enabled: true

prometheusOperator:
  enabled: true
EOF

# ============================================================================
# Install / Upgrade
# ============================================================================

helm upgrade --install ${RELEASE_NAME} \
prometheus-community/kube-prometheus-stack \
--namespace ${NAMESPACE} \
-f monitoring-values.yaml \
--wait \
--timeout 30m

# ============================================================================
# Verify
# ============================================================================

echo ""
echo "Waiting for pods..."

kubectl wait \
--for=condition=Ready pod \
--all \
-n ${NAMESPACE} \
--timeout=900s

echo ""
echo "Pods:"
kubectl get pods -n ${NAMESPACE}

echo ""
echo "Services:"
kubectl get svc -n ${NAMESPACE}

echo ""
echo "Grafana LoadBalancer:"
kubectl get svc ${RELEASE_NAME}-grafana \
-n ${NAMESPACE}

echo ""
echo "Prometheus:"
kubectl get svc \
-n ${NAMESPACE} | grep prometheus

echo ""
echo "Deployment completed."
