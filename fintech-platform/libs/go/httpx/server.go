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
