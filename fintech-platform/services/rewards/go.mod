module github.com/your-org/your-repo/services/rewards

go 1.22

require (
    github.com/jackc/pgx/v5 v5.5.4
    github.com/segmentio/kafka-go v0.4.47
)

replace github.com/your-org/your-repo/libs/go => ../../libs/go
