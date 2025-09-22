# Shared Python Base

This directory contains shared dependencies and utilities for all Python services in the fintech platform.

## 📦 Common Dependencies

The `requirements.common.txt` file includes:

- **FastAPI**: Modern, fast web framework for building APIs
- **Uvicorn**: ASGI server for running FastAPI applications
- **SQLAlchemy**: Python SQL toolkit and ORM
- **Alembic**: Database migration tool for SQLAlchemy
- **psycopg**: PostgreSQL adapter for Python
- **Pydantic**: Data validation using Python type annotations
- **python-dotenv**: Load environment variables from .env files
- **httpx**: Async HTTP client
- **aiokafka**: Async Kafka client
- **structlog**: Structured logging

## 🔧 Usage

Each service includes this in their `requirements.txt`:

```txt
-r ../_pybase/requirements.common.txt
```

This ensures all services use the same versions and have consistent dependencies.

## 🚀 Benefits

- **Consistency**: All services use the same dependency versions
- **Maintenance**: Update dependencies in one place
- **Security**: Centralized dependency management
- **Performance**: Shared base reduces build times
- **Compatibility**: Ensures inter-service compatibility
