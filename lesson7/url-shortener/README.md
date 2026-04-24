# Lesson 7 Final Practice: Short Link Lab

## Goal

Deploy a ready-made product to Kubernetes without writing application code.

Students will deploy a short link service that can:

1. Open a web UI.
2. Create a short link from a long URL.
3. Redirect `/r/<code>` to the original URL.
4. Keep data after the API Pod is recreated.
5. Keep data after the PostgreSQL Pod is recreated.
6. Show how the same product can be installed with one Helm command.

## Architecture

```text
Browser
  |
  v
Ingress short.local
  |-- /         -> Frontend Deployment -> url-frontend-service
  |-- /api      -> API Deployment      -> url-api-service
  |-- /r/<code> -> API Deployment      -> url-api-service
                                      |
                                      v
                           PostgreSQL StatefulSet
                                      |
                                      v
                                     PVC
```

## Folder Layout

| Path | Purpose |
|---|---|
| `api/` | Express API source code, migration, and Dockerfile |
| `frontend/` | Static frontend source code and Dockerfile |
| `k8s/` | Step-by-step Kubernetes YAML for students |
| `helm/url-shortener/` | Helm chart for one-command install and upgrade |
| `local-smoke-test.sh` | Instructor-only Docker smoke test for local verification |

## Image Prerequisite

The Kubernetes YAML and Helm chart use these public image tags:

```text
yanchen184/url-shortener-api:v1
yanchen184/url-shortener-frontend:v1
```

Before class, verify that both images exist:

```bash
docker manifest inspect yanchen184/url-shortener-api:v1 >/dev/null
docker manifest inspect yanchen184/url-shortener-frontend:v1 >/dev/null
```

If either image is missing, publish the course app images first. In the course site repo, the GitHub Actions workflow `.github/workflows/build-apps.yml` builds and pushes these images when the `apps/**` changes are pushed to `master`, assuming `DOCKERHUB_TOKEN` is configured.

The local smoke test does not require these public tags because it builds temporary local images from `api/` and `frontend/`.

## Two-Hour Teaching Flow

| Time | Activity | Expected Result |
|---|---|---|
| 0-10 min | Product demo and architecture | Students know what they are deploying |
| 10-25 min | Namespace, Secret, ConfigMap | Runtime boundary and configuration are ready |
| 25-45 min | PostgreSQL StatefulSet + PVC | Database is running and storage is persistent |
| 45-60 min | Migration Job | `short_links` table exists |
| 60-80 min | API Deployment + Service | `/health`, `/ready`, and `/api/links` are reachable |
| 80-95 min | Frontend Deployment + Service | Web UI is running |
| 95-110 min | Ingress + HPA | `short.local` routes traffic and API can autoscale |
| 110-120 min | Validation and Helm wrap-up | Students can explain manual YAML vs Helm |

## Manual Kubernetes Deployment

Run from this directory:

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-secret.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/03-postgres.yaml
kubectl apply -f k8s/04-migrate-job.yaml
kubectl apply -f k8s/05-api.yaml
kubectl apply -f k8s/06-frontend.yaml
kubectl apply -f k8s/07-hpa.yaml
kubectl apply -f k8s/08-ingress.yaml
```

Check the system:

```bash
kubectl get all -n url-shortener
kubectl get pvc -n url-shortener
kubectl get hpa -n url-shortener
kubectl get ingress -n url-shortener
```

Add local DNS mapping if needed:

```bash
sudo sh -c 'echo "<NODE-IP> short.local" >> /etc/hosts'
```

Validate from the browser:

```text
http://short.local
```

Validate with curl:

```bash
curl -s http://short.local/health
curl -s http://short.local/ready
curl -s -X POST http://short.local/api/links \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://kubernetes.io/","custom_code":"k8stest"}'
curl -I http://short.local/r/k8stest
```

## Failure Validation

Delete the API Pod:

```bash
kubectl delete pod -l app=url-api -n url-shortener
kubectl get pods -n url-shortener -w
```

Expected result: the Deployment creates replacement Pods.

Delete the database Pod:

```bash
kubectl delete pod postgres-0 -n url-shortener
kubectl get pod postgres-0 -n url-shortener -w
```

Expected result: the StatefulSet recreates `postgres-0`, the same PVC is mounted again, and previously created links remain available.

## Helm Install

After students complete the manual flow, show the one-command install:

```bash
helm install url-shortener ./helm/url-shortener \
  -n url-shortener \
  --create-namespace
```

Upgrade with values:

```bash
helm upgrade url-shortener ./helm/url-shortener \
  -n url-shortener \
  --set replicaCount.api=3 \
  --set hpa.maxReplicas=10 \
  --set ingress.host=short.demo.local \
  --set resources.api.requests.cpu=150m
```

Rollback:

```bash
helm rollback url-shortener 1 -n url-shortener
```

## Values Students Can Tune

| Value | Meaning |
|---|---|
| `image.tag` | Product version to deploy |
| `replicaCount.api` | API Pod count before HPA changes it |
| `replicaCount.frontend` | Frontend Pod count |
| `resources.api.requests.cpu` | API CPU request, also the HPA baseline |
| `resources.api.limits.memory` | API memory ceiling |
| `hpa.enabled` | Enable or disable autoscaling |
| `hpa.minReplicas` / `hpa.maxReplicas` | Autoscaling lower and upper bounds |
| `ingress.host` | Public hostname |
| `postgres.storageSize` | PostgreSQL PVC size |
| `secret.postgresPassword` | Lab database password placeholder |

## Cleanup

```bash
kubectl delete namespace url-shortener
```

## Instructor Local Smoke Test

If the Kubernetes cluster is unavailable, instructors can still verify the app locally with Docker:

```bash
./local-smoke-test.sh
```

The script starts PostgreSQL, runs the migration, starts the API and frontend, adds a local nginx gateway to mimic Ingress, validates health/readiness/create/list/redirect behavior, recreates the API container, checks data still exists, and then removes all test containers and the test network.
