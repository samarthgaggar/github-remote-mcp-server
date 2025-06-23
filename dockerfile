# Build stage for GitHub MCP server
FROM golang:1.23-alpine AS build

ARG VERSION="dev"

# Set the working directory
WORKDIR /build

# Install git
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache git

# Copy source code
COPY . .

# Build the server
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=${VERSION} -X main.commit=$(git rev-parse HEAD) -X main.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    -o /bin/github-mcp-server cmd/github-mcp-server/main.go

# Create startup script with better error handling and debugging
RUN printf '#!/bin/sh\nset -e\necho "=== MCP GitHub Server Startup ==="\necho "Testing GitHub MCP server binary..."\nif ! /usr/local/bin/github-mcp-server --help >/dev/null 2>&1; then\n    echo "Warning: GitHub MCP server test failed, but continuing..."\nfi\necho "Starting mcp-proxy with GitHub MCP server..."\necho "Command: mcp-proxy --host 0.0.0.0 --port 8080 --debug --pass-environment /usr/local/bin/github-mcp-server stdio"\nexec mcp-proxy --host 0.0.0.0 --port 8080 --debug --pass-environment /usr/local/bin/github-mcp-server stdio "$@"\n' > /start-server.sh

# Final stage with mcp-proxy
FROM ghcr.io/sparfenyuk/mcp-proxy:latest

# Install additional dependencies if needed
RUN python3 -m ensurepip && pip install --no-cache-dir uv

# Set environment variables
ENV PATH="/usr/local/bin:$PATH" \
    UV_PYTHON_PREFERENCE=only-system

# Copy the GitHub MCP server binary and startup script from build stage
COPY --from=build /bin/github-mcp-server /usr/local/bin/github-mcp-server
COPY --from=build /start-server.sh /usr/local/bin/start-server.sh

# Make them executable
RUN chmod +x /usr/local/bin/github-mcp-server && \
    chmod +x /usr/local/bin/start-server.sh

# Expose the port for HTTP interface
EXPOSE 8080

# Set working directory
WORKDIR /app

# Use the startup script
ENTRYPOINT ["/usr/local/bin/start-server.sh"]

# Default empty CMD
CMD []
