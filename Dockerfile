FROM golang:1.22-alpine AS builder

# Disable CGO (static binary) and turn Go modules off since the project still uses dep/vendor.
ENV CGO_ENABLED=0 \
    GO111MODULE=off

# Set-up working directory inside GOPATH so that legacy builds still work.
WORKDIR /go/src/github.com/monzo/calico-accountant

# Copy source code
COPY . .

# Build the binary. The ldflags strip debug information to reduce the final size.
RUN go build -ldflags="-s -w" -o /calico-accountant .

# ----------------------------------------------------------------------------
# Final runtime image
# ----------------------------------------------------------------------------
FROM alpine:3.18

LABEL maintainer="Jack Kleeman <jack@monzo.com>"

# Install runtime dependencies – iptables provides iptables-save which the
# application relies on. ca-certificates is added for any TLS communication.
RUN apk add --no-cache iptables ca-certificates && \
    update-ca-certificates

# Copy the statically-linked binary from the builder stage
COPY --from=builder /calico-accountant /calico-accountant

# Run as root because iptables requires elevated privileges.
USER root

ENTRYPOINT ["/calico-accountant"]
