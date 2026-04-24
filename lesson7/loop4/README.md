# Loop 4 — 從零建完整系統（任務排程系統）

系統架構：Frontend → Backend API → Redis Queue → Task Runner → MySQL

## 部署順序

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secret.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-mysql.yaml
kubectl wait pod/mysql-0 -n tasks --for=condition=Ready --timeout=120s
kubectl apply -f 04-redis.yaml
kubectl apply -f 05-db-migrate-job.yaml
kubectl apply -f 06-rbac.yaml
kubectl apply -f 07-backend.yaml
kubectl apply -f 08-frontend.yaml
kubectl apply -f 09-task-runner.yaml
kubectl apply -f 10-cronjob.yaml
kubectl apply -f 11-hpa.yaml
kubectl apply -f 12-ingress.yaml
```

## 清理

```bash
kubectl delete namespace tasks
```

## 檔案說明

| 檔案 | 說明 |
|------|------|
| 00-namespace.yaml | tasks namespace |
| 01-secret.yaml | MySQL / Redis / JWT 密碼 |
| 02-configmap.yaml | DB 連線設定、Redis 設定 |
| 03-mysql.yaml | MySQL StatefulSet + Headless Service + PVC |
| 04-redis.yaml | Redis Deployment + Service |
| 05-db-migrate-job.yaml | DB migration Job |
| 06-rbac.yaml | Backend SA + Role + RoleBinding |
| 07-backend.yaml | Backend API Deployment + Service |
| 08-frontend.yaml | Frontend Deployment + Service |
| 09-task-runner.yaml | Task Runner Deployment |
| 10-cronjob.yaml | 每分鐘觸發的排程 CronJob |
| 11-hpa.yaml | Backend HPA（CPU 70%） |
| 12-ingress.yaml | Traefik Ingress + strip-api-prefix Middleware |
