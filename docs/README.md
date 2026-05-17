# SkillPulse — GitHub Actions & Kubernetes Masterclass

[![CI](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/ci.yml)
[![CD](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/cd-k8s.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/cd-k8s.yml)
[![Security Scan](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/docker-image-scan.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/docker-image-scan.yml)
[![Dependency Scan](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/dependency-scan.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/dependency-scan.yml)
[![Secrets Scan](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/secrets-scan.yml/badge.svg)](https://github.com/YOUR_GITHUB_USERNAME/github-actions-kubernetes-masterclass/actions/workflows/secrets-scan.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Replace `YOUR_GITHUB_USERNAME` in the badge URLs above with your actual GitHub username.**

A small, real application with a real CI/CD pipeline. The app — SkillPulse — lets you track skills you're learning and the hours you put in. The point isn't the app. The point is everything around it: how a single `git push` becomes a running update on a server in under two minutes, with no human pressing any button.

This repo is the working demo for the **TrainWithShubham GitHub Actions & Kubernetes Masterclass**.

> **New here? Two beginner-friendly companion guides:**
>
> - [`docs/skillpulse-cicd-guide.pdf`](docs/skillpulse-cicd-guide.pdf) — chapter one. 29 pages on the GitHub Actions pipeline: DevOps foundations, CI/CD, containers, deploying to a real EC2, plus resume + interview prep.
> - [`docs/skillpulse-kubernetes-guide.pdf`](docs/skillpulse-kubernetes-guide.pdf) — chapter two. 32 pages on running this app on a local `kind` cluster: Kubernetes primitives, manifest walkthrough, the dev loop, real failures we hit (arch mismatches, port collisions), interview prep.
> - [`docs/architecture.md`](docs/architecture.md) — pipeline + application architecture diagrams (Mermaid).

---

## Why DevOps matters

For most of software's history, the people who *wrote* software and the people who *ran* it were two different teams with two different goals.

- Developers wanted to ship features.
- Operations wanted stability.

The fastest way for ops to be stable was to slow developers down. The fastest way for developers to ship was to throw code over the wall. Both teams were right. Both teams were also miserable. And the customer paid the price — releases happened once a quarter, every release was scary, and bugs took weeks to fix.

DevOps is the cultural and technical answer to that: *the same team owns the change all the way to production, and tooling makes that safe.* It's not a job title. It's a way of working that says small, frequent, automated, and reversible beats big, rare, manual, and irreversible — every time.

When DevOps is working you can tell because:

- **Deploys are boring.** Friday afternoon, Monday morning, doesn't matter.
- **Rollbacks are cheap.** A bad deploy is a 30-second fix, not an incident.
- **Feedback is fast.** A broken commit fails CI in minutes, not "after QA next sprint."
- **Ownership is clear.** The person who wrote the code is the person who watches it ship.

You get there by automating the path from a developer's laptop to production. That automation is called a **pipeline**.

---

## Why CI/CD is the heart of DevOps

CI/CD is two ideas wearing one acronym.

- **Continuous Integration** — every change, from every developer, gets built and tested automatically the moment it lands. You catch breakage in minutes, not days. Merge conflicts shrink because nobody's branch lives for two weeks.
- **Continuous Delivery / Deployment** — every change that passes CI is automatically packaged and shipped — to staging, or all the way to production. There is no "deploy day." Every commit is a candidate release.

The reason this matters: the cost of fixing a bug grows with the time between writing it and finding it. CI/CD shortens that gap to minutes. The reason it's hard: the only way to make it work is to *automate everything*. Build, test, package, deploy, verify. No "just run this script on my laptop" steps. If a human has to remember it, it will eventually be forgotten — and then it will fail at 2 a.m.

---

## Why GitHub Actions

A pipeline needs a runner — something that watches your repo, executes your build/test/deploy steps, and reports back. Historically that meant standing up a Jenkins server, paying for CircleCI, or wiring something custom. All of those still work; none of them are the lowest-friction option in 2026.

GitHub Actions wins on three things:

1. **It lives where the code lives.** No separate server, no separate auth, no separate UI. Your `.github/workflows/*.yml` files are part of the repo — they evolve with the code, get reviewed in the same PRs, and survive every clone.
2. **It's free for public repos and generous for private ones.** A complete CI/CD pipeline costs zero rupees to start.
3. **The Marketplace is enormous.** Need to SSH into a server? `appleboy/ssh-action`. Need to log in to Docker Hub? `docker/login-action`. You compose pre-built blocks instead of writing bash from scratch.

The trade-off is GitHub lock-in. For most teams, that's a fair price for the integration.

---

## What this project demonstrates

A production-grade pipeline, end to end.

```
┌─────────────┐     git push / PR    ┌──────────────────────────────────────────┐
│  Developer  ├─────────────────────▶│  GitHub Repo                             │
└─────────────┘                      └───────────────────┬──────────────────────┘
                                                         │ on: push / pull_request
                                                         ▼
                                      ┌──────────────────────────────────────────┐
                                      │  CI — parallel quality gates             │
                                      │  golangci-lint · Gitleaks · govulncheck  │
                                      │  Hadolint · tfsec · unit tests           │
                                      │       ↓ all pass                         │
                                      │  Docker build & push (short SHA tag)     │
                                      │       ↓                                  │
                                      │  Trivy image scan + SBOM (Syft)          │
                                      └───────────────────┬──────────────────────┘
                                                         │ workflow_run: success
                                                         ▼
                                      ┌──────────────────────────────────────────┐
                                      │  CD — staging → approval → production    │
                                      │  Deploy → skillpulse-staging namespace   │
                                      │       ↓ smoke test passes                │
                                      │  ⏸ Manual approval (GitHub Environment) │
                                      │       ↓ approved                         │
                                      │  Deploy → skillpulse (production)        │
                                      │  HPA · PDB · NetworkPolicy · Kyverno     │
                                      │       ↓ 3× self-heal smoke test          │
                                      │  ✅ Live  OR  🔙 Auto-rollback + alert   │
                                      └──────────────────────────────────────────┘
```

See [`docs/architecture.md`](docs/architecture.md) for full Mermaid diagrams.

### Secrets and variables needed

| Secret | What it is |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub account name |
| `DOCKERHUB_TOKEN` | A Docker Hub Personal Access Token (read+write) |
| `EC2_HOST` | Public IP or DNS of the deploy target |
| `EC2_USER` | Linux user on the EC2 (typically `ubuntu`) |
| `EC2_SSH_KEY` | Private key contents — paste the entire `.pem` file |
| `MYSQL_ROOT_PASSWORD` | MySQL root password |
| `MYSQL_DATABASE` | Database name |
| `MYSQL_USER` | Application DB user |
| `MYSQL_PASSWORD` | Application DB password |
| `SLACK_WEBHOOK_URL` | (optional) Slack incoming webhook for failure alerts |

| Variable | Value |
|---|---|
| `DEPLOY_ENABLED` | Set to `true` to enable pushes and deploys (default: off) |
| `SLACK_ENABLED` | Set to `true` to enable Slack alerts on failure |

---

## The application itself

A three-tier app — kept tiny on purpose so the pipeline is the star.

| Tier | Tech | What it does |
|---|---|---|
| Frontend | HTML + CSS + vanilla JS, served by Nginx | UI for adding skills and logging hours |
| Backend | Go 1.26 + Gin | REST API at `/api/...` |
| Database | MySQL 8.4 | Stores skills and learning logs |

Nginx in the frontend image also reverse-proxies `/api/` and `/health` to the backend, so the public surface is a single port.

API surface:

```
GET    /api/skills              list skills + total hours
POST   /api/skills              create skill
GET    /api/skills/:id          one skill + its logs
DELETE /api/skills/:id          delete skill (cascades logs)
POST   /api/skills/:id/log      log a study session
GET    /api/dashboard           summary counters
GET    /health                  DB ping for healthchecks
GET    /metrics                 Prometheus metrics endpoint
```

---

## Run it locally

```bash
cp .env.example .env             # fill in DOCKERHUB_USERNAME (anything works for local)
docker compose up -d --build
```

Open http://localhost. Backend port 8080 is intentionally not exposed — all traffic goes through Nginx, exactly like production.

To tear down:

```bash
docker compose down -v           # -v also drops the MySQL volume
```

---

## Run on Kubernetes (kind)

Same app, same images, same external port — but now every primitive a student would see in production: namespace, deployment, service, statefulset, configmap, secret, pvc, networkpolicy, hpa, pdb.

**Prerequisites:** Docker Desktop running, plus `brew install kind kubectl`.

```bash
make up                          # creates the kind cluster + applies manifests
# visit http://localhost:8888
make down                        # deletes the cluster (and the MySQL data with it)
```

### How traffic flows

```
host browser            kind cluster (1 control-plane + 2 workers)
http://localhost:8888
        │
        ▼ (kind extraPortMappings: hostPort 8888 → nodePort 30080)
   Service frontend (NodePort 30080)
        │
        ▼
   Deployment frontend (nginx + static)  ← HPA: 2–4 replicas
        │ proxy_pass http://backend:8080
        ▼
   Service backend (ClusterIP 8080)
        │
        ▼
   Deployment backend (Go + Gin)         ← HPA: 2–5 replicas
        │ DB_HOST=mysql
        ▼
   Service mysql (Headless 3306)
        │
        ▼
   StatefulSet mysql + 1Gi PVC + ConfigMap-mounted init.sql
```

### Manifest layout

```
k8s/
  kind-config.yaml          cluster: 1 control-plane + 2 workers
  00-namespace.yaml          namespace: skillpulse
  10-mysql.yaml              ConfigMap + headless Service + StatefulSet + PVC
  20-backend.yaml            Deployment + ClusterIP Service + startupProbe
  30-frontend.yaml           Deployment + NodePort Service (30080)
  40-network-policy.yaml     default deny-all + explicit allow rules
  50-pdb.yaml                PodDisruptionBudgets (backend + frontend)
  60-monitoring.yaml         ServiceMonitor + PrometheusRule (Prometheus operator)
  70-kyverno-policies.yaml   5 admission-time security policies
  80-hpa.yaml                HorizontalPodAutoscalers (backend + frontend)
```

### Useful commands

| Command | What it does |
|---|---|
| `make status` | One-screen view of pods, services, endpoints |
| `make logs` | Tail all three workloads at once |
| `make mysql` | Open a `mysql` shell in the StatefulSet pod |
| `make restart` | Roll backend + frontend (e.g. after pushing a new image) |

### Smoke test

```bash
curl http://localhost:8888/health                 # → {"status":"healthy"}
curl http://localhost:8888/api/dashboard          # → seed-data counters
curl -s http://localhost:8888/ | grep '<title>'   # → HTML title containing "SkillPulse"
```

---

## Reliability controls

| Control | What it does |
|---|---|
| `startupProbe` | Gives backend 60s to connect to MySQL before liveness kicks in |
| `livenessProbe` | Restarts pod if app hangs or deadlocks |
| `readinessProbe` | Removes pod from load balancer if it can't serve traffic |
| `PodDisruptionBudget` | Ensures at least 1 pod stays up during node drains |
| `HorizontalPodAutoscaler` | Scales backend 2–5 replicas on CPU >60%, memory >75% |
| Rolling update `maxUnavailable: 0` | Zero-downtime deploys |
| Graceful shutdown (30s) | Drains in-flight requests before pod is terminated |
| Staging gate | Every deploy hits staging namespace + smoke test before production |
| Manual approval | Production requires human sign-off via GitHub Environment |
| 3× self-heal smoke tests | Auto-restarts and retests before triggering rollback |
| Auto-rollback | Reverts to last known-good revision on deploy failure |

## Security controls

| Control | What it does |
|---|---|
| Gitleaks | Scans full Git history for leaked secrets on every PR |
| govulncheck | Checks Go stdlib and module CVEs |
| Hadolint | Lints Dockerfiles for best practices |
| tfsec | Scans Terraform for misconfigurations, uploads SARIF to Security tab |
| Trivy | Scans built images for CRITICAL/HIGH CVEs, uploads SARIF |
| SBOM (Syft) | Generates SPDX Software Bill of Materials, retained 90 days |
| Kyverno (5 policies) | Enforces: non-root, drop ALL caps, no privilege escalation, resource limits, no :latest |
| NetworkPolicy | Default deny-all + explicit allow: frontend→backend, backend→mysql only |
| seccompProfile | RuntimeDefault on all pods |
| readOnlyRootFilesystem | Backend runs with no writable filesystem |
| Non-root user | Backend Dockerfile creates and runs as `appuser` |
| CODEOWNERS | All PRs require review from designated owners |
| Dependabot | Weekly PRs for Actions, Go modules, Docker base images |

---

## Project layout

```
backend/                Go service
  Dockerfile            multi-stage: golang → alpine, runs as non-root appuser
  main.go               wires routes, graceful shutdown on SIGTERM
  database/db.go        connects to MySQL with retry-loop
  handlers/             skills, logs, dashboard, health endpoints
  handlers/handlers_test.go  unit tests
  models/               request/response structs
  models/models_test.go unit tests

frontend/               static UI + Nginx config
  Dockerfile            FROM nginx:unprivileged, copies html/css/js + nginx.conf
  index.html, css/, js/ vanilla — no build step
  nginx.conf            serves the site, proxies /api/ to backend:8080

mysql/init.sql          schema + seed data
docker-compose.yml      three services: db, backend, frontend
.env.example            copy to .env

.github/workflows/
  ci.yml                     main CI orchestrator (parallel quality gates → build → scan)
  cd-k8s.yml                 CD: staging → approval → production kind cluster
  code-quality.yml           golangci-lint (reusable)
  secrets-scan.yml           Gitleaks (reusable)
  dependency-scan.yml        govulncheck (reusable)
  docker-lint.yml            Hadolint (reusable)
  docker-image-scan.yml      Trivy + SBOM (reusable)
  docker_build_push.yml      build & push (reusable)
  terraform-scan.yml         tfsec (reusable)
  unit-tests.yml             go test + coverage (reusable)
  dependabot.yml             weekly auto-PRs

k8s/                    Kubernetes manifests (see above)
terraform/              EC2 + SG + key pair + Ansible hosts.ini generation
ansible/
  playbook.yml           install Docker, kind, kubectl on EC2
  install-observability.yml  install Helm + kube-prometheus-stack
docs/
  architecture.md        pipeline + application architecture diagrams
  skillpulse-cicd-guide.pdf
  skillpulse-kubernetes-guide.pdf
CODEOWNERS              mandatory review rules
```

---

## Credits

Built for the [TrainWithShubham](https://www.youtube.com/@TrainWithShubham) community. If this repo helped you understand a real CI/CD pipeline end to end, share it forward — that's how the community grows.
