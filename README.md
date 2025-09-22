# Fintech Platform

A microservices-based fintech platform built with Go and Python, featuring a comprehensive suite of financial services including card issuance, risk assessment, compliance checking, and transaction processing.

## Architecture

This platform consists of multiple microservices:

- **Issuer Gateway**: Card issuance and management
- **Ledger**: Transaction recording and accounting
- **Risk Assessment**: Fraud detection and risk scoring
- **Compliance**: AML/KYC checks and regulatory compliance
- **Reconciliation**: Settlement and reconciliation processing
- **Notifier**: Event notifications and alerts
- **Rewards**: Points and loyalty program management

## Technology Stack

- **Backend**: Go and Python (FastAPI)
- **Database**: PostgreSQL
- **Message Queue**: Apache Kafka
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Infrastructure**: Terraform
- **Frontend**: Next.js (Admin interface)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Go 1.19+
- Python 3.9+
- Node.js 18+

### Running the Platform

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/fintech-platform.git
   cd fintech-platform
   ```

2. **Start with Docker Compose**
   ```bash
   cd fintech-platform
   docker-compose up -d
   ```

3. **Access the services**
   - Admin Interface: http://localhost:3000
   - Test Interface: http://localhost:8080/test-interface.html
   - API Documentation: Available at each service's `/docs` endpoint

## Services

### Core Services
- **Issuer Gateway** (Port 8081): Card issuance and management
- **Ledger** (Port 8082): Transaction recording
- **Risk Assessment** (Port 8084): Fraud detection
- **Compliance** (Port 8085): Regulatory checks
- **Reconciliation** (Port 8086): Settlement processing
- **Notifier** (Port 8087): Event notifications

### Infrastructure
- **PostgreSQL**: Primary database
- **Kafka**: Event streaming
- **Redis**: Caching and session storage

## Development

### Python Services
```bash
cd services/[service-name]-py
pip install -r requirements.txt
python app.py
```

### Go Services
```bash
cd services/[service-name]
go mod tidy
go run main.go
```

## API Documentation

Each service provides OpenAPI documentation at `/docs` endpoint when running.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
