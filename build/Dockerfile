# Build stage
FROM golang:1.25.3-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Copy entire project
COPY . .

# Verify that go.mod exists

# Download dependencies
RUN go mod download

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-X main.version=${VERSION} -X main.buildTime=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -a -installsuffix cgo -o main ./cmd/app

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -S app && adduser -S app -G app

WORKDIR /home/app

# Copy binary from builder
COPY --from=builder /app/main .
COPY --from=builder /app/configs/config.prod.yaml ./configs/config.yaml

# Change ownership to app user
RUN chown -R app:app /home/app

USER app

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./main"]