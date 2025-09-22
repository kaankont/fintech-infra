module github.com/your-org/your-repo/services/ledger

go 1.22

require (
    github.com/go-chi/chi/v5 v5.0.12
    github.com/jackc/pgx/v5 v5.5.4
)

replace github.com/your-org/your-repo/libs/go => ../../libs/go
