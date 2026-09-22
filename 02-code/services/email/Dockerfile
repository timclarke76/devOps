FROM golang:1.25-alpine
RUN apk add --no-cache curl

EXPOSE 8080
CMD ["/usr/local/bin/service"]

WORKDIR /usr/src/service
COPY *.mod *.sum *.go *.sql .
RUN go mod download && go build -v -o /usr/local/bin/service ./...
