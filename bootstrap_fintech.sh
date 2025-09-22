#!/usr/bin/env bash
set -euo pipefail

# bootstrap_fintech.sh
# Scaffolds a production-lean monorepo for a card-issuing + payments fintech stack
# Starter stack: Go (chi) microservices, Postgres, Redis, Kafka, OpenAPI, Terraform on AWS, GitHub Actions CI, Next.js Admin UI
# Usage: bash bootstrap_fintech.sh your-org your-repo

ORG_NAME=${1:-stealth}
REPO_NAME=${2:-fintech-platform}
ROOT_DIR="${REPO_NAME}"

say() { printf "\033[1;32m==> %s\033[0m\n" "$*"; }
err() { printf "\033[1;31m[error]\033[0m %s\n" "$*" 1>&2; }

mkdir -p "$ROOT_DIR"
cd "$ROOT_DIR"

git init -q

echo "# ${REPO_NAME}

Stealth fintech platform (card issuing + payments infra).
" > README.md

echo "node_modules\n.next\n.env*\n**/.env*\n.DS_Store\n/tmp\n/vendor\n/dist\n/build\n/.idea\n/.vscode\n/bin\n/coverage\n*.log\n**/terraform.tfstate*\n**/.terraform\n**/.terraform.lock.hcl\n" > .gitignore

# Workspace layout
say "Creating workspace layout"
mkdir -p services/{issuer-gateway,ledger,rewards,risk,compliance,recon,notifier}
mkdir -p platform/{pkg,internal}
mkdir -p libs/{go,schemas,sql}
mkdir -p infra/{docker,k8s,terraform,github}
mkdir -p apps/admin
mkdir -p ops/{migrations,docs,runbooks}
mkdir -p .cursor

# Top-level devcontainer + compose
say "Writing docker-compose for local stack"
cat > infra/docker/docker-compose.yml <<'YML'
version: "3.9"
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USER: postgres
      POSTGRES_DB: fintech
    ports: ["5432:5432"]
    volumes:
      - pgdata:/var/lib/postgresql/data
  redis:
    image: redis:7
    ports: ["6379:6379"]
  kafka:
    image: bitnami/kafka:3.6
    environment:
      - KAFKA_ENABLE_KRAFT=yes
      - KAFKA_CFG_NODE_ID=1
      - KAFKA_CFG_PROCESS_ROLES=broker,controller
      - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093
      - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092
      - KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@localhost:9093
    ports: ["9092:9092"]
  jaeger:
    image: jaegertracing/all-in-one:1.57
    ports: ["16686:16686", "4317:4317", "4318:4318"]
  issuer-gateway:
    build: ../../services/issuer-gateway
    env_file:
      - ../../services/issuer-gateway/.env.example
    ports: ["8081:8080"]
    depends_on: [postgres, redis, kafka]
  ledger:
    build: ../../services/ledger
    env_file:
      - ../../services/ledger/.env.example
    ports: ["8082:8080"]
    depends_on: [postgres, kafka]
  rewards:
    build: ../../services/rewards
    env_file:
      - ../../services/rewards/.env.example
    ports: ["8083:8080"]
    depends_on: [postgres, kafka]
volumes:
  pgdata:
YML

# Shared Go module
say "Initializing shared Go module"
mkdir -p libs/go/otel
mkdir -p libs/go/httpx
cat > libs/go/go.mod <<MOD
module github.com/${ORG_NAME}/${REPO_NAME}/libs/go

go 1.22
MOD

cat > libs/go/otel/otel.go <<'GO'
package otel

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

func Tracer(name string) trace.Tracer { return otel.Tracer(name) }
func Start(ctx context.Context, name string) (context.Context, trace.Span) { return Tracer("app").Start(ctx, name) }
GO

cat > libs/go/httpx/server.go <<'GO'
package httpx

import (
    "log"
    "net/http"
    "time"
)

type Server struct{ *http.Server }

func New(addr string, handler http.Handler) *Server {
    return &Server{&http.Server{
        Addr:              addr,
        Handler:           handler,
        ReadHeaderTimeout: 5 * time.Second,
    }}
}

func (s *Server) Start() {
    log.Printf("http listening on %s", s.Addr)
    log.Fatal(s.ListenAndServe())
}
GO

# OpenAPI skeletons
say "Adding OpenAPI specs"
mkdir -p libs/schemas
cat > libs/schemas/issuer-gateway.openapi.yaml <<'YAML'
openapi: 3.0.3
info:
  title: Issuer Gateway API
  version: 0.1.0
paths:
  /health:
    get:
      summary: Liveness check
      responses:
        '200': { description: OK }
  /v1/cards:
    post:
      summary: Issue a new card
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                user_id: { type: string }
                product_id: { type: string }
      responses:
        '201': { description: Created }
YAML

cat > libs/schemas/ledger.openapi.yaml <<'YAML'
openapi: 3.0.3
info: { title: Ledger API, version: 0.1.0 }
paths:
  /health:
    get: { responses: { '200': { description: OK } } }
  /v1/postings:
    post:
      summary: Create double-entry posting
      responses: { '201': { description: Created } }
YAML

# SQL migrations
say "Seeding SQL migrations"
mkdir -p libs/sql/migrations
cat > libs/sql/migrations/0001_init.sql <<'SQL'
-- accounts and postings (double-entry)
CREATE TABLE IF NOT EXISTS accounts (
  id BIGSERIAL PRIMARY KEY,
  owner_id TEXT NOT NULL,
  currency CHAR(3) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS postings (
  id BIGSERIAL PRIMARY KEY,
  debit_account BIGINT NOT NULL REFERENCES accounts(id),
  credit_account BIGINT NOT NULL REFERENCES accounts(id),
  amount NUMERIC(18,2) NOT NULL,
  currency CHAR(3) NOT NULL,
  ref TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
SQL

# Service template generator (Go + chi)
service_template() {
  local svc="$1"
  say "Scaffolding service: $svc"
  mkdir -p services/$svc
  pushd services/$svc >/dev/null
  cat > go.mod <<MOD
module github.com/${ORG_NAME}/${REPO_NAME}/services/${svc}

go 1.22

require (
	github.com/go-chi/chi/v5 v5.0.12
	github.com/joho/godotenv v1.5.1
)

replace github.com/${ORG_NAME}/${REPO_NAME}/libs/go => ../../libs/go
MOD

  cat > main.go <<'GO'
package main

import (
  "log"
  "net/http"
  "os"
  "github.com/go-chi/chi/v5"
  httpx "github.com/stealth/fintech-platform/libs/go/httpx"
)

func main() {
  _ = os.Setenv("TZ", "UTC")
  r := chi.NewRouter()
  r.Get("/health", func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(200); w.Write([]byte("ok")) })
  addr := ":8080"
  if v := os.Getenv("PORT"); v != "" { addr = ":"+v }
  httpx.New(addr, r).Start()
  log.Println("stopped")
}
GO

  cat > Dockerfile <<'DOCKER'
FROM golang:1.22 as build
WORKDIR /src
COPY . .
RUN go mod download && CGO_ENABLED=0 go build -o /out/app

FROM gcr.io/distroless/base-debian12
COPY --from=build /out/app /app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
DOCKER

  cat > .env.example <<ENV
PORT=8080
DATABASE_URL=postgres://postgres:postgres@postgres:5432/fintech?sslmode=disable
REDIS_URL=redis://redis:6379
KAFKA_BROKERS=localhost:9092
ENV

  popd >/dev/null
}

for svc in issuer-gateway ledger rewards risk compliance recon notifier; do
  service_template "$svc"
done

# Issuer-Gateway domain routes
say "Adding domain routes to issuer-gateway"
cat > services/issuer-gateway/routes.go <<'GO'
package main

import (
  "encoding/json"
  "net/http"
  "github.com/go-chi/chi/v5"
)

type IssueCardReq struct { UserID string `json:"user_id"`; ProductID string `json:"product_id"` }

func routes(r *chi.Mux) {
  r.Post("/v1/cards", func(w http.ResponseWriter, r *http.Request) {
    var req IssueCardReq
    _ = json.NewDecoder(r.Body).Decode(&req)
    w.WriteHeader(http.StatusCreated)
    w.Write([]byte(`{"card_id":"card_123"}`))
  })
}
GO

# Wire routes in main
perl -0777 -pe 's|(r := chi.NewRouter\(\)\n\s*r\.Get\("/health"[\s\S]*?\))|$1\n  routes(r)|' -i services/issuer-gateway/main.go || true

# Admin app (Next.js minimal)
say "Creating Admin UI (Next.js)"
cat > apps/admin/package.json <<'PKG'
{
  "name": "admin",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.5",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  }
}
PKG

mkdir -p apps/admin/pages
cat > apps/admin/pages/index.tsx <<'TSX'
import { useEffect, useState } from 'react'
export default function Home(){
  const [health, setHealth] = useState('…')
  useEffect(()=>{ fetch('http://localhost:8081/health').then(r=>r.text()).then(setHealth).catch(()=>setHealth('down')) },[])
  return (<main style={{fontFamily:'ui-sans-serif',padding:24}}>
    <h1>Fintech Admin</h1>
    <p>Issuer Gateway health: <b>{health}</b></p>
  </main>)
}
TSX

# GitHub Actions CI
say "Adding CI pipeline"
mkdir -p .github/workflows
cat > .github/workflows/ci.yml <<'YML'
name: ci
on:
  push: { branches: [ main ] }
  pull_request:
jobs:
  go-services:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.22' }
      - name: Build services
        run: |
          for s in services/*; do (cd "$s" && go build ./...); done
  admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - name: Install & build
        run: |
          cd apps/admin && npm ci || npm i && npm run build
YML

# Kubernetes skeleton
say "Adding K8s manifests"
mkdir -p infra/k8s/base/issuer-gateway
cat > infra/k8s/base/issuer-gateway/deployment.yml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: { name: issuer-gateway }
spec:
  replicas: 2
  selector: { matchLabels: { app: issuer-gateway } }
  template:
    metadata: { labels: { app: issuer-gateway } }
    spec:
      containers:
        - name: app
          image: ghcr.io/ORG/REPO/issuer-gateway:sha-REV
          ports: [{ containerPort: 8080 }]
          env:
            - { name: PORT, value: "8080" }
YAML

# Terraform skeleton (AWS)
say "Adding Terraform skeleton"
mkdir -p infra/terraform/envs/dev
cat > infra/terraform/envs/dev/main.tf <<'TF'
terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }
variable "region" { default = "us-west-2" }
# Add RDS, EKS, VPC modules as you iterate
TF

# .cursor rules for Cursor agent
say "Adding Cursor agent rules"
cat > .cursor/rules.md <<'MD'
# Cursor Project Rules
- Code in small, reviewable PRs.
- Keep PCI scope minimal; never handle raw PAN in our code.
- Every service must expose `/health` and structured JSON logs.
- Prefer idempotent POST endpoints with Idempotency-Key.
- Add unit tests before adding new endpoints.
MD

# Makefile helpers
say "Adding Makefile"
cat > Makefile <<'MK'
.PHONY: up down build
up:
	docker compose -f infra/docker/docker-compose.yml up -d --build

e2e:
	curl -s localhost:8081/health && echo && curl -s -X POST localhost:8081/v1/cards -d '{"user_id":"u1","product_id":"p1"}' -H 'Content-Type: application/json' && echo

down:
	docker compose -f infra/docker/docker-compose.yml down -v

build:
	for s in services/*; do (cd $$s && go build ./...); done
MK

say "Done! Next steps:"
cat <<MSG
1) cd ${REPO_NAME}
2) make up     # brings up Postgres/Redis/Kafka + 3 services
3) make e2e    # hit health + sample card issue
4) Open apps/admin (npm i && npm run dev) and visit http://localhost:3000
5) Use Cursor to iterate: open TODOs in services/* and libs/schemas/*.openapi.yaml
MSG
