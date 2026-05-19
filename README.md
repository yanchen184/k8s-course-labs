# Kubernetes 課程實作檔案

> **搭配 Udemy / 企業內訓 K8s 課程的完整動手 lab 倉。** 從 Pod 入門到生產就緒,4 堂課共 31 個 lab,每個 lab 對應一個能 `kubectl apply` 的 YAML。

**講師**：陳彥彤 YC（Java 後端 8 年 · AI 工程師 2 年）｜[bobchen184@gmail.com](mailto:bobchen184@gmail.com) ｜ [品牌站](https://yanchen184.github.io/ai-lecturer-bob/)

---

## 課程結構

| 堂數 | 主題 | Lab 數 | 對應資料夾 |
|:---:|------|:---:|---|
| **第 4 堂** | K8s 全貌 + Pod + Deployment 入門 | 7 | [`lesson4/`](lesson4/) |
| **第 5 堂** | Deployment + Service + DNS + Namespace | 7 | [`lesson5/`](lesson5/) |
| **第 6 堂** | Ingress + ConfigMap + Secret + PV/PVC + StatefulSet + Helm | 8 | [`lesson6/`](lesson6/) |
| **第 7 堂** | 生產就緒 — Probe + Resources + HPA + RBAC + NetworkPolicy + DaemonSet + CronJob + 短網址實作 | 9 | [`lesson7/`](lesson7/) |

每個 lesson 資料夾都有自己的 `README.md`,寫清楚每個 lab 的指令、預期結果、踩坑解析。

---

## 怎麼用這個倉

### 1. 先有環境

```bash
# 課程預設用 minikube（第 4-5 堂）+ k3s（第 6-7 堂）
minikube status      # 第 4-5 堂
kubectl get nodes    # 兩個環境通用
```

### 2. 進到對應堂數

```bash
cd lesson4
cat README.md        # 看 lab 清單
kubectl apply -f pod.yaml
```

### 3. 出錯了?看 answers/

每個 lesson 有 `answers/` 子資料夾放正確答案。**先自己寫一次再對照**,直接抄沒收穫。

---

## 為什麼這份內容值得學

- **每個 lab 都對應一個真實會遇到的場景** — 不是「Hello World」式範例
  - `pod-broken.yaml` → 故意 image 拼錯,讓你看 `ImagePullBackOff`
  - `pod-crash.yaml` → 故意讓 container crash,看退避策略
  - `broken-pv-pvc.yaml` → 故意 storageClass 不對,看怎麼 debug
  - `pod-mysql-broken.yaml` → MySQL 沒設密碼會 crash,排錯練習
- **從入門到生產就緒** — 不只教指令,教 HPA、Resource limits、NetworkPolicy、RBAC 這些上線後才會痛的東西
- **第 7 堂的最終 lab 是部署一個短網址服務** — 不寫程式碼,純粹用 K8s 把後端 + 資料庫 + Ingress 串起來,證明你會了

---

## 課程資訊

- 講師:陳彥彤 YC
- 對應 Udemy 課程:[即將上架]
- 企業內訓客製化:來信討論 → [bobchen184@gmail.com](mailto:bobchen184@gmail.com)
- 更多教學內容:[ai-lecturer-bob](https://yanchen184.github.io/ai-lecturer-bob/)

---

## License

MIT — 課程學員可自由使用、改寫、做為內部教學素材。
