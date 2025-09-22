# Python Migration Guide

This fintech platform has been converted from Go to Python-first architecture while maintaining the same microservices design and infrastructure.

## 🐍 New Python Stack

- **Web Framework**: FastAPI (async, auto-docs, type hints)
- **Database ORM**: SQLAlchemy 2.x + Alembic migrations
- **Event Streaming**: aiokafka (async Kafka client)
- **HTTP Client**: httpx (async HTTP client)
- **Environment**: python-dotenv
- **Server**: Uvicorn (ASGI server)

## 📁 Service Structure

```
services/
├── _pybase/                    # Shared Python dependencies
│   └── requirements.common.txt
├── issuer-gateway-py/          # Card issuing service
├── ledger-py/                  # Double-entry accounting
├── rewards-py/                 # Points & rewards (Kafka consumer)
├── risk-py/                    # Risk assessment
├── compliance-py/              # AML/KYC compliance
├── recon-py/                   # Reconciliation
└── notifier-py/                # Notifications
```

## 🚀 Quick Start

### 1. Start the Platform
```bash
# Bring up all services (Postgres, Redis, Kafka, Jaeger + Python services)
make up

# Apply database migrations
make db-apply

# Test end-to-end flow
make e2e
```

### 2. Manual Testing
```bash
# Health checks
curl localhost:8081/health  # Issuer Gateway
curl localhost:8082/health  # Ledger
curl localhost:8083/health  # Rewards (consumer)

# Issue a card (triggers ledger posting + Kafka event + rewards accrual)
curl -X POST localhost:8081/v1/cards \
  -H 'Content-Type: application/json' \
  -d '{"user_id":"u_demo","product_id":"p_standard"}'

# Check rewards were accrued
psql postgresql://postgres:postgres@localhost:5432/fintech \
  -c "SELECT * FROM rewards_ledger ORDER BY id DESC LIMIT 5;"
```

## 🔧 Development

### Adding New Services
1. Create `services/your-service-py/`
2. Copy `requirements.txt` with `-r ../_pybase/requirements.common.txt`
3. Create `app.py` with FastAPI app
4. Add to `docker-compose.yml`
5. Update port mappings

### Database Migrations
```bash
# For ledger service (uses Alembic)
cd services/ledger-py
alembic revision --autogenerate -m "description"
alembic upgrade head

# For other services (raw SQL)
# Add to libs/sql/migrations/ and run via make db-apply
```

### Local Development
```bash
# Run individual service locally
cd services/issuer-gateway-py
pip install -r requirements.txt
uvicorn app:app --reload --port 8081

# Or use Docker
docker build -t issuer-gateway-py .
docker run -p 8081:8080 --env-file .env issuer-gateway-py
```

## 📊 Service Endpoints

### Issuer Gateway (`:8081`)
- `GET /health` - Health check
- `POST /v1/cards` - Issue new card

### Ledger (`:8082`)
- `GET /health` - Health check
- `POST /v1/postings` - Create double-entry posting

### Rewards (`:8083`)
- Kafka consumer (no HTTP endpoints)
- Listens to `postings` topic
- Accrues 1% points on transactions

### Risk (`:8084`)
- `GET /health` - Health check
- `POST /v1/assess` - Risk assessment

### Compliance (`:8085`)
- `GET /health` - Health check
- `POST /v1/check` - Compliance check

### Recon (`:8086`)
- `GET /health` - Health check
- `POST /v1/reconcile` - Reconciliation

### Notifier (`:8087`)
- `GET /health` - Health check
- `POST /v1/notify` - Send notification

## 🔄 Event Flow

1. **Card Issuance**: POST to issuer-gateway
2. **Ledger Posting**: Issuer calls ledger service
3. **Kafka Event**: Issuer emits posting event
4. **Rewards Accrual**: Rewards service consumes event
5. **Database Update**: Points added to rewards_ledger

## 🐳 Docker Services

All Python services use:
- Python 3.11 slim base image
- Multi-stage builds (optional)
- Health checks
- Environment variable configuration
- Proper dependency management

## 🧪 Testing

```bash
# Run all tests
make test

# Individual service tests
cd services/issuer-gateway-py
pytest

# Integration tests
make e2e
```

## 📈 Monitoring

- **Jaeger**: Distributed tracing (port 16686)
- **Health Checks**: All services expose `/health`
- **Structured Logging**: Using structlog
- **Metrics**: Ready for Prometheus integration

## 🔒 Security Notes

- PCI scope kept minimal (no raw PAN handling)
- Idempotency keys for safe retries
- Environment-based configuration
- Proper input validation with Pydantic

## 🚀 Production Deployment

- Kubernetes manifests in `infra/k8s/`
- Terraform for AWS infrastructure
- GitHub Actions CI/CD
- Docker multi-stage builds for optimization

## 📚 Next Steps

1. Add comprehensive test suites
2. Implement OpenTelemetry tracing
3. Add Prometheus metrics
4. Enhance error handling and retries
5. Add API documentation with FastAPI auto-docs
6. Implement proper authentication/authorization
7. Add rate limiting and circuit breakers
