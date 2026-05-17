# Stage 1: Build
FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY . .
RUN go mod tidy && CGO_ENABLED=0 GOOS=linux go build -o skillpulse .

# Stage 2: Run
FROM alpine:3.23

RUN apk --no-cache add ca-certificates=20260413-r0

# Create non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app/skillpulse .

# Ensure the binary is owned by appuser
RUN chown appuser:appgroup /app/skillpulse

USER appuser

EXPOSE 8080

CMD ["./skillpulse"]

