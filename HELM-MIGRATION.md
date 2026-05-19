# SkillPulse — Helm-based Kubernetes Deployment

## What changed and why

The previous approach patched raw YAML files with `sed`/`awk` inside the CI
script. This is inherently fragile: `sed` operates on text, not on YAML
structure, so any formatting difference (indentation, trailing spaces, blank
lines) can produce `"mapping values are not allowed in this context"` — the
exact error that triggered this refactor.

**The fix:** replace all shell-based YAML patching with a Helm chart. Helm
templates are rendered by a proper YAML-aware engine, so values are injected
correctly regardless of surrounding whitespace.

---

## New directory layout

```
k8s/
├── kind-config.yaml                  ← unchanged (cluster infra, not app config)
└── helm/
    └── skillpulse/                   ← single Helm chart for the whole app
        ├── Chart.yaml
        ├── values.yaml               ← production defaults
        ├── values-staging.yaml       ← staging overrides (applied on top)
        └── templates/
            ├── _helpers.tpl
            ├── 00-namespace.yaml
            ├── 10-mysql.yaml         ← ConfigMap + Service + StatefulSet
            ├── 20-backend.yaml       ← Service + Deployment
            ├── 30-frontend.yaml      ← Service (nodePort from values) + Deployment
            ├── 40-network-policy.yaml
            ├── 50-pdb.yaml
            ├── 60-monitoring.yaml    ← guarded by monitoring.enabled
            ├── 70-kyverno-policies.yaml
            └── 80-hpa.yaml
```

---

## What differs per environment

| Setting | Staging | Production |
|---|---|---|
| `namespace` | `skillpulse-staging` | `skillpulse` |
| `frontend.nodePort` | `30081` → port 8889 | `30080` → port 8888 |
| `frontend.replicas` | `1` | `2` |
| `backend.replicas` | `1` | `2` |
| `backend.hpa.minReplicas` | `1` | `2` |
| `frontend.hpa.minReplicas` | `1` | `2` |
| `monitoring.enabled` | `false` | `false` (set `true` when prometheus-operator is installed) |
| `smokeTest.mode` | `dockerexec` | `portforward` |

All differences live in `values-staging.yaml`. No shell patching needed.

---

## Deploy commands

### Staging
```bash
helm upgrade --install skillpulse ./k8s/helm/skillpulse \
  --namespace skillpulse-staging \
  --create-namespace \
  -f ./k8s/helm/skillpulse/values-staging.yaml \
  --set image.tag=${IMAGE_TAG} \
  --set image.dockerUser=${DOCKER_USER} \
  --atomic \
  --timeout 10m \
  --wait
```

### Production
```bash
helm upgrade --install skillpulse ./k8s/helm/skillpulse \
  --namespace skillpulse \
  --create-namespace \
  -f ./k8s/helm/skillpulse/values.yaml \
  --set image.tag=${IMAGE_TAG} \
  --set image.dockerUser=${DOCKER_USER} \
  --atomic \
  --timeout 20m \
  --wait
```

### Rollback (manual)
```bash
# List revisions
helm history skillpulse --namespace skillpulse

# Roll back to previous revision
helm rollback skillpulse --namespace skillpulse --wait
```

---

## Secrets

Secrets are **never** stored in the chart. They are injected at deploy time
by the CD workflow using GitHub Actions secrets:

```bash
kubectl create secret generic skillpulse-db \
  --namespace="$NAMESPACE" \
  --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  --from-literal=MYSQL_DATABASE="$MYSQL_DATABASE" \
  --from-literal=MYSQL_USER="$MYSQL_USER" \
  --from-literal=MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  --save-config \
  --dry-run=client -o yaml | kubectl apply -f -
```

This is idempotent (safe to re-run) and keeps secrets out of Git and Helm
release history.

---

## Installing Helm on the EC2 host

The `cluster-setup` job in `cd-k8s.yml` auto-installs Helm if it is not
present:

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Local dry-run (validate templates without a cluster)

```bash
helm template skillpulse ./k8s/helm/skillpulse \
  -f ./k8s/helm/skillpulse/values-staging.yaml \
  --set image.tag=abc1234 \
  --set image.dockerUser=myuser \
  --debug
```

This renders all templates to stdout so you can visually verify the YAML
before pushing.

---

## Migration from the old raw-manifest approach

1. **Delete the old `k8s/*.yaml` manifests** (except `kind-config.yaml`).
2. **Copy** the `k8s/helm/` directory from this PR into your repo.
3. **Update** `.github/workflows/cd-k8s.yml` with the version from this PR.
4. On first deploy, Helm will create the release from scratch. Subsequent
   deploys use `helm upgrade` which is fully idempotent.
5. If you have existing workloads deployed with raw `kubectl apply`, annotate
   them to adopt them into the Helm release:
   ```bash
   kubectl annotate deployment backend \
     meta.helm.sh/release-name=skillpulse \
     meta.helm.sh/release-namespace=skillpulse \
     --namespace skillpulse --overwrite
   kubectl label deployment backend \
     app.kubernetes.io/managed-by=Helm \
     --namespace skillpulse --overwrite
   ```
