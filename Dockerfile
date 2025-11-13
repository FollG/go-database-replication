FROM golang:1.25.3-alpine

WORKDIR /app

# Копируем исходники
COPY . .

# Собираем приложение
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/app

EXPOSE 8080

CMD ["./main"]