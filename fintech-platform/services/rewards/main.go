package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/segmentio/kafka-go"
)

type PostingReq struct {
	DebitAccount  int64   `json:"debit_account"`
	CreditAccount int64   `json:"credit_account"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency"`
	Ref           string  `json:"ref"`
}

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://postgres:postgres@postgres:5432/fintech?sslmode=disable"
	}
	db, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// HTTP health
	go func() {
		http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) { w.Write([]byte("ok")) })
		log.Println("rewards http :8080")
		http.ListenAndServe(":8080", nil)
	}()

	brokers := strings.Split(os.Getenv("KAFKA_BROKERS"), ",")
	if len(brokers) == 0 || brokers[0] == "" {
		brokers = []string{"localhost:9092"}
	}

	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers: brokers,
		Topic:   "postings",
		GroupID: "rewards-consumer",
	})
	defer r.Close()

	log.Println("rewards consuming from postings")
	for {
		m, err := r.ReadMessage(context.Background())
		if err != nil {
			log.Println("kafka read:", err)
			time.Sleep(time.Second)
			continue
		}
		var p PostingReq
		if err := json.Unmarshal(m.Value, &p); err != nil {
			log.Println("json:", err)
			continue
		}

		points := p.Amount * 0.01
		userID := string(m.Key)
		if userID == "" {
			// fallback: parse from ref "signup-<id>"
			if strings.HasPrefix(p.Ref, "signup-") {
				userID = strings.TrimPrefix(p.Ref, "signup-")
			} else {
				userID = "unknown"
			}
		}

		_, err = db.Exec(context.Background(),
			"insert into rewards_ledger (user_id, points, posting_ref) values ($1,$2,$3)",
			userID, strconv.FormatFloat(points, 'f', 4, 64), p.Ref)
		if err != nil {
			log.Println("insert:", err)
		}
		log.Printf("accrued %.4f points for user=%s ref=%s", points, userID, p.Ref)
	}
}
