FROM golang as builder
WORKDIR /go/src/github.com/deploji/deploji-worker
ENV GO111MODULE=on
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/deploji-worker .

FROM alpine/ansible:2.16.1
RUN apk update && apk --no-cache add ca-certificates py3-lxml tar curl \
    python3-dev py3-pip bash krb5 krb5-dev gcc musl-dev py3-jmespath py3-lxml pipx
RUN pipx install --include-deps "pywinrm>=0.3.0" "pywinrm[kerberos]" && pipx ensurepath
RUN ansible-galaxy collection install community.general ansible.windows community.windows
WORKDIR /root/
ENV SSH_KNOWN_HOSTS=/root/known_hosts
RUN touch known_hosts
COPY --from=builder /go/bin/deploji-worker .
COPY .env .
COPY templates/*.html templates/
VOLUME /root/storage
CMD ["./deploji-worker"]
