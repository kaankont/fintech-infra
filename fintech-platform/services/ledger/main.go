package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	httpx "github.com/your-org/your-repo/libs/go/httpx"
)

type PostingReq struct {
	DebitAccount  int64   `json:"debit_account"`
	CreditAccount int64   `json:"credit_account"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency"` // "USD"
	Ref           string  `json:"ref"`      // idempotency ref
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL required")
	}
	db, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	r := chi.NewRouter()
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })

	r.Post("/v1/postings", func(w http.ResponseWriter, r *http.Request) {
		var p PostingReq
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		tx, err := db.Begin(r.Context())
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		defer tx.Rollback(r.Context())

		var exists int
		if p.Ref != "" {
			if err := tx.QueryRow(r.Context(), "select 1 from postings where ref=$1 limit 1", p.Ref).Scan(&exists); err == nil {
				w.WriteHeader(200)
				w.Write([]byte(`{"status":"already_posted"}`))
				return
			}
		}

		_, err = tx.Exec(r.Context(),
			`insert into postings (debit_account, credit_account, amount, currency, ref)
       values ($1,$2,$3,$4,$5)`,
			p.DebitAccount, p.CreditAccount, p.Amount, p.Currency, p.Ref,
		)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		if err := tx.Commit(r.Context()); err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		w.WriteHeader(201)
		w.Write([]byte(`{"status":"posted"}`))
	})

	addr := ":8080"
	if v := os.Getenv("PORT"); v != "" {
		addr = ":" + v
	}
	httpx.New(addr, r).Start()
}
