FROM alpine:3 as alpine
RUN apk add -U --no-cache ca-certificates

FROM golang as golang

WORKDIR /src

ADD go.mod .
ADD go.sum .
RUN go mod download
ADD . .
RUN go build -ldflags "-extldflags '-static'" ./cmd/drone-autoscaler

FROM scratch

EXPOSE 8080 80 443
VOLUME /data

ENV GODEBUG netdns=go
ENV XDG_CACHE_HOME /data
ENV DRONE_DATABASE_DRIVER sqlite3
ENV DRONE_DATABASE_DATASOURCE /data/database.sqlite?cache=shared&mode=rwc&_busy_timeout=9999999

COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=golang /src/drone-autoscaler /bin/

ENTRYPOINT ["/bin/drone-autoscaler"]