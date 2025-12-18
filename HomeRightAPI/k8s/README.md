# Kubernetes (k8s) deployment

This folder contains **kustomize-ready** Kubernetes manifests for running:

- `homeright-api` (FastAPI)
- `mongo` (MongoDB 7) with a persistent volume claim

## Prereqs

- A Kubernetes cluster (Docker Desktop, kind, EKS, GKE, AKS, etc.)
- `kubectl`
- (Recommended) `kustomize` (or `kubectl apply -k`)

## 1) Build/publish the API image

The Deployment expects an image named `homeright-api:latest` by default.

### Local cluster (kind / Docker Desktop)

Build the image:

```bash
cd HomeRightAPI
docker build -t homeright-api:latest .
```

If you use kind, load the image into the cluster:

```bash
kind load docker-image homeright-api:latest
```

For a remote cluster, push to a registry and update `k8s/api-deployment.yaml` image.

## 2) Deploy

```bash
kubectl apply -k HomeRightAPI/k8s
```

## 3) Access the API

Port-forward:

```bash
kubectl -n homeright port-forward svc/homeright-api 8000:8000
```

Open:
- `http://localhost:8000/docs`

## Notes

- MongoDB is deployed as a StatefulSet with a PVC (`ReadWriteOnce`) and `mongo` user/pass stored in a Secret.
- The API uses `MONGODB_URI` pointing to the in-cluster Mongo service.
- For production:
  - Use a managed MongoDB or a hardened Mongo helm chart.
  - Add TLS, authn/authz, rate limiting, and proper secrets management.

