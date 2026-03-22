# 第四堂：Pod 實作

## 事前準備

```bash
# 確認 minikube 在跑
minikube status
kubectl get nodes
```

## Lab 清單

| Lab | 檔案 | 學什麼 |
|:---:|------|--------|
| 1 | `pod.yaml` | 第一個 Pod：部署 nginx，完整 CRUD |
| 2 | `pod-broken.yaml` | 排錯練習：image 名字拼錯，找出問題並修好 |
| 3 | `pod-crash.yaml` | CrashLoopBackOff 體驗：觀察重啟退避策略 |
| 4 | `pod-sidecar.yaml` | Sidecar 模式：nginx + busybox 共享 Volume |
| 5 | `pod-httpd.yaml` | 自由練習：換一個不同的 image |

## Lab 1：第一個 Pod

```bash
kubectl apply -f pod.yaml
kubectl get pods
kubectl get pods -o wide
kubectl describe pod my-nginx
kubectl logs my-nginx
kubectl exec -it my-nginx -- /bin/sh
# 進去後試試：
curl localhost
ls /usr/share/nginx/html/
exit

# port-forward 在瀏覽器看頁面
kubectl port-forward pod/my-nginx 8080:80
# 開瀏覽器 → http://localhost:8080

# 清理
kubectl delete pod my-nginx
```

## Lab 2：排錯練習

```bash
kubectl apply -f pod-broken.yaml
kubectl get pods               # 看到 ImagePullBackOff
kubectl get pods --watch       # 觀察狀態變化（Ctrl+C 停止）
kubectl describe pod broken-pod # 拉到最下面看 Events → 找到錯誤原因

# 修正：把 pod-broken.yaml 裡的 image 改成 nginx:1.27
kubectl delete pod broken-pod
kubectl apply -f pod-broken.yaml
kubectl get pods               # 應該變成 Running
```

## Lab 3：CrashLoopBackOff 體驗

```bash
kubectl apply -f pod-crash.yaml
kubectl get pods --watch       # 觀察重啟間隔：10s → 20s → 40s → ...
# Ctrl+C 停止觀察
kubectl describe pod crash-pod # 看 Events 裡的 Back-off
kubectl logs crash-pod         # 看到 "hello"

# 清理
kubectl delete pod crash-pod
```

## Lab 4：Sidecar 多容器 Pod

```bash
kubectl apply -f pod-sidecar.yaml
kubectl get pods               # 看 READY 欄位：2/2

# 製造流量
kubectl exec -it sidecar-pod -c nginx -- /bin/sh
curl localhost
curl localhost
curl localhost
exit

# 從 Sidecar 看日誌
kubectl logs sidecar-pod -c log-reader    # 看到三次 access log
kubectl logs sidecar-pod -c nginx         # 對比 nginx 的 stdout

# 清理
kubectl delete pod sidecar-pod
```

## Lab 5：自由練習

```bash
kubectl apply -f pod-httpd.yaml
kubectl get pods
kubectl exec -it my-httpd -- /bin/sh
# 提示：httpd image 裡沒有 curl，試試其他方式看歡迎頁面

# 清理
kubectl delete pod my-httpd
```

## 學完驗證清單

- [ ] `kubectl get nodes` 看到 Ready
- [ ] 能獨立寫 Pod YAML 部署 nginx
- [ ] `port-forward` 後瀏覽器看到 nginx 頁面
- [ ] 看到 `ImagePullBackOff` 能用 `describe` 找到原因
- [ ] 看到 `CrashLoopBackOff` 知道是容器啟動後 crash
- [ ] Sidecar Pod 的 `READY` 顯示 `2/2`
- [ ] 會用 `-c` 指定看哪個容器的日誌

## 反思問題（下堂課會回答）

> 你用 `kubectl delete pod my-nginx` 把 Pod 刪了，它就真的消失了，沒人幫你重建。
> 如果這是生產環境的 API 服務，使用者就斷線了。
>
> **問題：怎麼讓 K8s 自動幫你維持「隨時有 3 個 nginx 在跑」？Pod 掛了一個，自動補一個新的？**
