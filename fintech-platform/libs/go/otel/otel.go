package otel

import (
    "context"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

func Tracer(name string) trace.Tracer { return otel.Tracer(name) }
func Start(ctx context.Context, name string) (context.Context, trace.Span) { return Tracer("app").Start(ctx, name) }
