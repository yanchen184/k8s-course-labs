# 總複習 12 步：一行一行跑

> 前置條件：k3s 叢集已啟動、kubectl 可用、metrics-server 已安裝
> 所有指令都在 `lesson7/final-exam/` 目錄下執行

---

## Step 1：建 Namespace

```bash
kubectl apply -f namespace.yaml
```

```bash
kubectl get ns prod
```

---

## Step 2：建 Secret（DB 密碼）

```bash
kubectl apply -f secret.yaml
```

```bash
kubectl get secret -n prod
```

驗證密碼有存進去（生產環境不要這樣做）：

```bash
kubectl get secret db-secret -n prod -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 -d && echo
```

---

## Step 3：建 ConfigMap（API 設定 + nginx 設定）

```bash
kubectl apply -f configmap.yaml
```

```bash
kubectl get configmap -n prod
```

應該看到 `api-config` 和 `frontend-nginx-config` 兩個。

---

## Step 4：部署 MySQL（StatefulSet + PVC + Headless Service）

```bash
kubectl apply -f mysql-statefulset.yaml
```

等 MySQL 啟動（約 30-60 秒）：

```bash
kubectl get pods -n prod -w
```

> 看到 `mysql-0` 變成 `1/1 Running` 就 Ctrl+C

確認 PVC 自動建立：

```bash
kubectl get pvc -n prod
```

應該看到 `mysql-data-mysql-0`，狀態 `Bound`。

---

## Step 5：部署 API（Deployment + Probe + Resource + ConfigMap/Secret 注入）

```bash
kubectl apply -f api-deployment.yaml
```

```bash
kubectl get pods -n prod -l app=api
```

等 3 個 Pod 都是 `Running`。

---

## Step 6：部署前端（Deployment + ConfigMap volume）

```bash
kubectl apply -f frontend-deployment.yaml
```

```bash
kubectl get pods -n prod -l app=frontend
```

等 2 個 Pod 都是 `Running`。

---

## Step 7：建 Service（api-svc + frontend-svc）

```bash
kubectl apply -f services.yaml
```

```bash
kubectl get svc -n prod
```

應該看到 `api-svc`、`frontend-svc`（ClusterIP）+ 之前 Step 4 建的 `mysql-headless`。

---

## Step 8：建 Ingress（/ → 前端、/api → API）

```bash
kubectl apply -f ingress.yaml
```

```bash
kubectl get ingress -n prod
```

---

到這裡功能完整了！接下來加安全和彈性 ↓

---

## Step 9：設 NetworkPolicy（三層隔離）

```bash
kubectl apply -f networkpolicy.yaml
```

```bash
kubectl get networkpolicy -n prod
```

應該看到 `db-policy`、`api-policy`、`frontend-policy` 三條。

---

## Step 10：設 HPA（API CPU>70% 自動擴容，最多 10 Pod）

```bash
kubectl apply -f hpa.yaml
```

```bash
kubectl get hpa -n prod
```

---

## Step 11：完整驗證

一覽所有資源：

```bash
kubectl get all -n prod
```

```bash
kubectl get pvc -n prod
```

```bash
kubectl get ingress -n prod
```

```bash
kubectl get networkpolicy -n prod
```

```bash
kubectl get hpa -n prod
```

驗證 DNS（從叢集內解析 api-svc）：

```bash
kubectl run dns-test --image=busybox:1.36 -n prod --rm -it --restart=Never -- nslookup api-svc
```

驗證 Probe 有設定好：

```bash
kubectl describe pods -n prod -l app=api | grep -A5 "Liveness\|Readiness\|Startup"
```

驗證 NetworkPolicy（非 API Pod 連 DB 應該被擋）：

```bash
kubectl run test-block --image=busybox:1.36 -n prod --rm -it --restart=Never -- wget --timeout=3 -qO- http://mysql-headless:3306 2>&1 || echo "Blocked as expected!"
```

---

## Step 12：壓測觸發 HPA（選做）

確認 metrics-server 有裝：

```bash
kubectl top pods -n prod
```

終端 1 — 跑壓測：

```bash
kubectl run load-test --image=busybox:1.36 -n prod --rm -it --restart=Never -- sh -c "while true; do wget -qO- http://api-svc:80 > /dev/null 2>&1; done"
```

終端 2 — 觀察 HPA 擴容：

```bash
kubectl get hpa -n prod -w
```

> 等一兩分鐘，應該看到 REPLICAS 從 3 慢慢增加
> 壓測完 Ctrl+C，等幾分鐘 Pod 會自動縮回來

---

## 清理

```bash
kubectl delete namespace prod
```

一行搞定，prod 底下所有東西全刪。

---

## 檢查清單

- [ ] prod Namespace 建立成功
- [ ] Secret 和 ConfigMap 在 prod 裡
- [ ] MySQL StatefulSet Running + PVC Bound
- [ ] API 3 個 Pod Running
- [ ] 前端 2 個 Pod Running
- [ ] 3 個 Service 都在（api-svc、frontend-svc、mysql-headless）
- [ ] Ingress 規則正確
- [ ] 3 條 NetworkPolicy 生效
- [ ] HPA 設定成功，能看到 CPU metrics
- [ ] 壓測時 Pod 自動擴容
