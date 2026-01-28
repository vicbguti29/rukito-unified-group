# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod and sum files from the backend subfolder
COPY rukito-backend/go.mod rukito-backend/go.sum ./
RUN go mod download

# Copy the rest of the backend source code
COPY rukito-backend/ .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/server/main.go

# Final stage
FROM alpine:latest

WORKDIR /root/

# Copy the pre-built binary
COPY --from=builder /app/main .
# El archivo .env se manejará mediante variables de entorno en Render
# Pero copiamos el example por si acaso
COPY rukito-backend/.env.example .env

EXPOSE 8080

CMD ["./main"]
