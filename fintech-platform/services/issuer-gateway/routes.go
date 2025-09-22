package main

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/segmentio/kafka-go"
)

type IssueCardReq struct {
	UserID    string `json:"user_id"`
	ProductID string `json:"product_id"`
}
type PostingReq struct {
	DebitAccount  int64   `json:"debit_account"`
	CreditAccount int64   `json:"credit_account"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency"`
	Ref           string  `json:"ref"`
}

func routes(r *chi.Mux) {
	r.Post("/v1/cards", func(w http.ResponseWriter, r *http.Request) {
		var req IssueCardReq
		_ = json.NewDecoder(r.Body).Decode(&req)

		idemp := r.Header.Get("Idempotency-Key")
		if idemp == "" {
			idemp = "issue-" + req.UserID + "-" + req.ProductID
		}

		pr := PostingReq{DebitAccount: 1, CreditAccount: 2, Amount: 5.00, Currency: "USD", Ref: "signup-" + req.UserID}
		b, _ := json.Marshal(&pr)
		http.Post("http://ledger:8080/v1/postings", "application/json", bytes.NewReader(b))

		// Emit event to Kafka (best-effort)
		broker := os.Getenv("KAFKA_BROKERS")
		if broker != "" {
			wtr := &kafka.Writer{
				Addr:     kafka.TCP(broker),
				Topic:    "postings",
				Balancer: &kafka.LeastBytes{},
			}
			_ = wtr.WriteMessages(context.Background(), kafka.Message{
				Key:   []byte(req.UserID),
				Value: b,
				Time:  time.Now(),
			})
			_ = wtr.Close()
		}

		w.WriteHeader(http.StatusCreated)
		w.Write([]byte(`{"card_id":"card_` + req.UserID + `","idempotency_key":"` + idemp + `"}`))
	})
}
