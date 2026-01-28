# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/server/main.go

# Final stage
FROM alpine:latest

WORKDIR /root/

# Copy the pre-built binary
COPY --from=builder /app/main .
# Copy .env example or handle it via environment variables in the cloud
COPY .env.example .env

EXPOSE 8080

CMD ["./main"]
