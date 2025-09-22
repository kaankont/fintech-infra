module github.com/your-org/your-repo/services/issuer-gateway

go 1.22

require (
  github.com/go-chi/chi/v5 v5.2.3
  github.com/segmentio/kafka-go v0.4.47
)

require github.com/your-org/your-repo/libs/go v0.0.0-00010101000000-000000000000 // indirect

replace github.com/your-org/your-repo/libs/go => ../../libs/go
