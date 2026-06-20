#!/bin/bash

set -e

DIR="eks-production"

rm -rf $DIR eks-production.zip
mkdir -p $DIR

echo "Creating Kubernetes production files..."

# ---------------- Namespace ----------------
cat > $DIR/00-namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
EOF

# ---------------- Secrets ----------------
cat > $DIR/01-secrets.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: oracle-secret
  namespace: production
type: Opaque
stringData:
  ORACLE_PASSWORD: MANAGER
  APP_USER: RESERVATION
  APP_USER_PASSWORD: MANAGER
EOF

# ---------------- Oracle DB ----------------
cat > $DIR/02-oracle.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: oracle-db
  namespace: production
spec:
  clusterIP: None
  selector:
    app: oracle-db
  ports:
    - port: 1521
      targetPort: 1521
      name: oracle
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: oracle-db
  namespace: production
spec:
  serviceName: oracle-db
  replicas: 1
  selector:
    matchLabels:
      app: oracle-db
  template:
    metadata:
      labels:
        app: oracle-db
    spec:
      containers:
        - name: oracle
          image: gvenzl/oracle-xe:21-slim
          ports:
            - containerPort: 1521
          envFrom:
            - secretRef:
                name: oracle-secret
          volumeMounts:
            - name: oracle-data
              mountPath: /opt/oracle/oradata
  volumeClaimTemplates:
    - metadata:
        name: oracle-data
      spec:
        storageClassName: gp3
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 10Gi
EOF

# ---------------- Train App ----------------
cat > $DIR/03-train-app.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: train-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: train-app
  template:
    metadata:
      labels:
        app: train-app
    spec:
      containers:
        - name: train-app
          image: <your-ecr>/train-app:latest
          ports:
            - containerPort: 8080
          env:
            - name: DB_URL
              value: jdbc:oracle:thin:@oracle-db:1521/XEPDB1
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: oracle-secret
                  key: APP_USER
            - name: DB_PASS
              valueFrom:
                secretKeyRef:
                  name: oracle-secret
                  key: APP_USER_PASSWORD
EOF

# ---------------- Service ----------------
cat > $DIR/04-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: train-app
  namespace: production
spec:
  selector:
    app: train-app
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
EOF

# ---------------- Ingress ----------------
cat > $DIR/05-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: train-app-ingress
  namespace: production
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/healthcheck-path: /
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: train-app
                port:
                  number: 8080
EOF

# ---------------- HPA ----------------
cat > $DIR/06-hpa.yaml <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: train-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: train-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
EOF

# ---------------- ServiceMonitor ----------------
cat > $DIR/07-servicemonitor.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: train-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: train-app
  namespaceSelector:
    matchNames:
      - production
  endpoints:
    - port: http
      path: /actuator/prometheus
      interval: 30s
EOF

# ---------------- Prometheus Alerts ----------------
cat > $DIR/08-prometheusrule.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: train-app-alerts
  namespace: monitoring
spec:
  groups:
    - name: train-app
      rules:
        - alert: HighCPU
          expr: rate(container_cpu_usage_seconds_total[2m]) > 0.8
          for: 2m
          labels:
            severity: warning


        - alert: PodCrashLooping
          expr: increase(kube_pod_container_status_restarts_total[5m]) > 3
          for: 2m
          labels:
            severity: critical
EOF

# ---------------- Fluent Bit ----------------
cat > $DIR/09-fluentbit.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: logging
EOF

# ---------------- Monitoring Values ----------------
cat > $DIR/10-values-monitoring.yaml <<EOF
grafana:
  persistence:
    enabled: true
    storageClassName: gp3

prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
EOF

# ---------------- Install Script ----------------
cat > $DIR/install.sh <<'EOF'
#!/bin/bash

kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secrets.yaml
kubectl apply -f 02-oracle.yaml
kubectl apply -f 03-train-app.yaml
kubectl apply -f 04-service.yaml
kubectl apply -f 05-ingress.yaml
kubectl apply -f 06-hpa.yaml
kubectl apply -f 07-servicemonitor.yaml
kubectl apply -f 08-prometheusrule.yaml
kubectl apply -f 09-fluentbit.yaml
EOF

chmod +x $DIR/install.sh

# ---------------- ZIP ----------------
zip -r eks-production.zip $DIR > /dev/null

echo ""
echo "✅ DONE!"
echo "📦 File created: eks-production.zip"
echo ""
echo "Next steps:"
echo "unzip eks-production.zip"
echo "cd eks-production"
echo "bash install.sh"
