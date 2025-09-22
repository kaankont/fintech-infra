FROM golang:1.22 as build
WORKDIR /src
COPY . .
RUN go mod download && CGO_ENABLED=0 go build -o /out/app

FROM gcr.io/distroless/base-debian12
COPY --from=build /out/app /app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
