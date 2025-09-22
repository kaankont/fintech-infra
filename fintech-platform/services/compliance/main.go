package main

import (
  "log"
  "net/http"
  "os"
  "github.com/go-chi/chi/v5"
  httpx "github.com/your-org/your-repo/libs/go/httpx"
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
