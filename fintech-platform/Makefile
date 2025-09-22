.PHONY: up down build db-apply db-reset
up:
	docker compose -f infra/docker/docker-compose.yml up -d --build

e2e:
	curl -s localhost:8081/health && echo && curl -s -X POST localhost:8081/v1/cards -d '{"user_id":"u_demo","product_id":"p_standard"}' -H 'Content-Type: application/json' && echo

down:
	docker compose -f infra/docker/docker-compose.yml down -v

build:
	for s in services/*-py; do (cd $$s && python -m pip install -r requirements.txt); done

db-apply:
	psql postgresql://postgres:postgres@localhost:5432/fintech -f libs/sql/migrations/0001_init.sql
	psql postgresql://postgres:postgres@localhost:5432/fintech -f libs/sql/migrations/0002_rewards.sql

db-reset:
	psql postgresql://postgres:postgres@localhost:5432/fintech -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
	$(MAKE) db-apply
