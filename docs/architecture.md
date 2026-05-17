# SkillPulse — Architecture & Pipeline

## CI/CD pipeline

```mermaid
flowchart TD
    DEV([👨‍💻 Developer]) -->|git push / PR| GH[GitHub]

    GH --> CI

    subgraph CI ["🔄 CI Pipeline (ci.yml)"]
        direction TB
        P[Prepare — generate short SHA] --> QG

        subgraph QG ["Quality gates — run in parallel"]
            direction LR
            L[golangci-lint]
            S[Gitleaks\nsecrets scan]
            D[govulncheck\ndependency CVEs]
            H[Hadolint\nDockerfile lint]
            T[tfsec\nTerraform scan]
            U[Unit tests\n+ coverage]
        end

        QG -->|all pass| B["🐳 Docker build & push\n(backend + frontend)"]
        B --> SC["🔍 Trivy image scan\n+ SBOM (Syft)"]
    end

    CI -->|workflow_run success| CD

    subgraph CD ["🚀 CD Pipeline (cd-k8s.yml)"]
        direction TB
        STG["Deploy → staging namespace\nskillpulse-staging"]
        STG --> SMOKE1{Staging\nsmoke test}
        SMOKE1 -->|pass| GATE{"⏸ Manual approval\nGitHub Environment:\nproduction"}
        SMOKE1 -->|fail| FAIL1[❌ Stop — do not promote]
        GATE -->|approved| PROD["Deploy → production\nskillpulse namespace\non kind cluster / EC2"]
        PROD --> SMOKE2{"Smoke test\n3 self-heal attempts"}
        SMOKE2 -->|pass| DONE[✅ Live]
        SMOKE2 -->|fail after 3 attempts| RB["🔙 Auto-rollback\n+ GitHub issue\n+ Slack alert"]
    end
```

## Application architecture

```mermaid
flowchart LR
    USER([User / Browser]) -->|port 8888| FE

    subgraph K8S ["☸️ Kubernetes — kind cluster on EC2"]
        direction TB

        subgraph NS ["namespace: skillpulse"]
            FE["🌐 Frontend\nnginx:unprivileged\nNodePort 30080"]
            BE["⚙️ Backend\nGo + Gin\nClusterIP :8080"]
            DB[("🗄️ MySQL 8.4\nStatefulSet\nPVC 1Gi")]

            FE -->|/api/*\nreverse proxy| BE
            BE -->|port 3306| DB
        end

        subgraph OBS ["namespace: monitoring"]
            PROM["📊 Prometheus\nkube-prometheus-stack"]
            GRAF["📈 Grafana"]
            PROM --> GRAF
        end

        BE -->|/metrics\nServiceMonitor| PROM
    end
```

## Security controls

```mermaid
flowchart LR
    subgraph BUILD ["Build-time security"]
        A[Gitleaks — no secrets in Git]
        B[govulncheck — no Go CVEs]
        C[tfsec — no Terraform misconfigs]
        D[Hadolint — Dockerfile best practices]
        E[Trivy — no CRITICAL/HIGH in images]
        F[SBOM — full software bill of materials]
    end

    subgraph RUNTIME ["Runtime security — Kubernetes"]
        G[Kyverno — non-root containers enforced]
        H[Kyverno — capabilities.drop ALL]
        I[Kyverno — no privilege escalation]
        J[Kyverno — resource limits required]
        K[Kyverno — no :latest image tag]
        L[NetworkPolicy — default deny-all\n+ explicit allow rules only]
        M[Pod securityContext — seccomp RuntimeDefault]
        N[readOnlyRootFilesystem: true]
    end
```

## Reliability controls

| Control | What it does |
|---|---|
| `startupProbe` | Gives backend 60s to connect to MySQL before liveness kicks in |
| `livenessProbe` | Restarts pod if app hangs or deadlocks |
| `readinessProbe` | Removes pod from load balancer if it can't serve traffic |
| `PodDisruptionBudget` | Ensures at least 1 pod stays up during node drains / cluster upgrades |
| `HorizontalPodAutoscaler` | Scales backend 2–5 replicas on CPU >60% and memory >75% |
| Rolling update `maxUnavailable: 0` | Zero-downtime deploys — always keeps full capacity |
| Graceful shutdown (30s) | Drains in-flight requests before pod is terminated |
| 3 self-heal smoke tests | Automatically restarts and retests before triggering rollback |
| Auto-rollback | Reverts to last known-good revision on deploy failure |

## Repository structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                  # Main CI orchestrator
│   │   ├── cd-k8s.yml              # CD: staging → production
│   │   ├── code-quality.yml        # golangci-lint
│   │   ├── secrets-scan.yml        # Gitleaks
│   │   ├── dependency-scan.yml     # govulncheck
│   │   ├── docker-lint.yml         # Hadolint
│   │   ├── docker-image-scan.yml   # Trivy + SBOM
│   │   ├── docker_build_push.yml   # Build & push (reusable)
│   │   ├── terraform-scan.yml      # tfsec
│   │   └── unit-tests.yml          # Go test + coverage
│   └── dependabot.yml              # Weekly auto-PRs
├── backend/                        # Go + Gin REST API
├── frontend/                       # Nginx static site
├── k8s/                            # Kubernetes manifests
│   ├── 00-namespace.yaml
│   ├── 10-mysql.yaml               # MySQL StatefulSet
│   ├── 20-backend.yaml             # Backend Deployment + Service
│   ├── 30-frontend.yaml            # Frontend Deployment + NodePort
│   ├── 40-network-policy.yaml      # Default deny + allow rules
│   ├── 50-pdb.yaml                 # PodDisruptionBudgets
│   ├── 60-monitoring.yaml          # ServiceMonitor + PrometheusRule
│   ├── 70-kyverno-policies.yaml    # Admission control policies
│   └── 80-hpa.yaml                 # HorizontalPodAutoscalers
├── terraform/                      # EC2 + SG + key pair
├── ansible/
│   ├── playbook.yml                # Install Docker, kind, kubectl
│   └── install-observability.yml   # Install Helm + kube-prometheus-stack
└── docs/
    └── architecture.md             # This file
```
