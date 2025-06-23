GitHub MCP Server Docker
A containerized GitHub MCP (Model Context Protocol) server designed for deployment on Google Kubernetes Engine (GKE) with Server-Sent Events (SSE) support for remote connections.
Overview
This Docker image packages a GitHub MCP server built in Go with the mcp-proxy to enable HTTP/SSE access to MCP capabilities. The server provides GitHub integration functionality through the Model Context Protocol, making it accessible via HTTP endpoints for remote clients.
Features

GitHub Integration: Full MCP server implementation for GitHub operations
HTTP/SSE Support: Remote access via Server-Sent Events through mcp-proxy
GKE Ready: Optimized for Google Kubernetes Engine deployment
Multi-stage Build: Efficient Docker image with minimal runtime footprint
Debug Support: Built-in debugging capabilities for troubleshooting
Environment Passthrough: Supports environment variable configuration

Quick Start
Prerequisites

Docker installed
GitHub token (for authentication)
Kubernetes cluster (for production deployment)

Running Locally
bash# Build the image
docker build -t github-mcp-server .

# Run with GitHub token
docker run -p 8080:8080 \
  -e GITHUB_TOKEN=your_github_token \
  github-mcp-server
The server will be available at http://localhost:8080
Environment Variables
VariableDescriptionRequiredGITHUB_TOKENGitHub personal access tokenYesGITHUB_API_URLGitHub API base URL (default: https://api.github.com)NoLOG_LEVELLogging level (debug, info, warn, error)No
Deployment
Google Kubernetes Engine (GKE)

Create a Secret for GitHub Token:

bashkubectl create secret generic github-mcp-secret \
  --from-literal=github-token=your_github_token

Deploy using Kubernetes manifests:

yamlapiVersion: apps/v1
kind: Deployment
metadata:
  name: github-mcp-server
  labels:
    app: github-mcp-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: github-mcp-server
  template:
    metadata:
      labels:
        app: github-mcp-server
    spec:
      containers:
      - name: github-mcp-server
        image: your-registry/github-mcp-server:latest
        ports:
        - containerPort: 8080
        env:
        - name: GITHUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: github-mcp-secret
              key: github-token
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: github-mcp-service
spec:
  selector:
    app: github-mcp-server
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer

Apply the manifests:

bashkubectl apply -f deployment.yaml
Using Helm (Optional)
Create a values.yaml:
yamlreplicaCount: 3

image:
  repository: your-registry/github-mcp-server
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 8080

env:
  GITHUB_TOKEN: "your_github_token"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
API Endpoints
The mcp-proxy exposes the following endpoints:

GET / - Server information and capabilities
GET /sse - Server-Sent Events endpoint for real-time communication
POST /message - Send messages to the MCP server
GET /health - Health check endpoint
GET /ready - Readiness check endpoint

Configuration
Build Arguments
The Docker image supports the following build arguments:

VERSION: Version string (default: "dev")

Example:
bashdocker build --build-arg VERSION=1.0.0 -t github-mcp-server:1.0.0 .
Runtime Configuration
Configure the server behavior using environment variables:
bashdocker run -p 8080:8080 \
  -e GITHUB_TOKEN=ghp_xxxxxxxxxxxx \
  -e LOG_LEVEL=debug \
  -e GITHUB_API_URL=https://api.github.com \
  github-mcp-server
Development
Building from Source

Clone the repository
Build the Docker image:

bashdocker build -t github-mcp-server .
Testing
bash# Test the server locally
docker run --rm -p 8080:8080 \
  -e GITHUB_TOKEN=your_test_token \
  github-mcp-server

# Check health endpoint
curl http://localhost:8080/health
Testing with MCP Inspector
The MCP Inspector is a web-based tool for testing and debugging MCP servers. You can use it to test your GitHub MCP server both locally and when deployed to GKE.
Local Testing with MCP Inspector

Run your GitHub MCP server locally:

bashdocker run -p 8080:8080 \
  -e GITHUB_TOKEN=your_github_token \
  github-mcp-server

Open MCP Inspector: Visit https://github.com/modelcontextprotocol/inspector or use the hosted version at https://inspector.mcp.dev
Connect to your local server:

Connection Type: Select "HTTP/SSE"
Server URL: http://localhost:8080
Click "Connect"



Testing Deployed GKE Service with Port Forward
When your service is deployed to GKE, you can test it using kubectl port forwarding:

Port forward to the deployed service:

bash# Port forward to a specific pod
kubectl port-forward deployment/github-mcp-server 8080:8080

# Or port forward to the service
kubectl port-forward service/github-mcp-service 8080:80

Test the connection:

bash# Verify the server is accessible
curl http://localhost:8080/health

# Test SSE endpoint
curl -H "Accept: text/event-stream" http://localhost:8080/sse

Use MCP Inspector with port-forwarded service:

Keep the port-forward command running in a terminal
Open MCP Inspector in your browser
Connection Type: Select "HTTP/SSE"
Server URL: http://localhost:8080
Click "Connect"



Testing from External Load Balancer
If you have a LoadBalancer service with an external IP:

Get the external IP:

bashkubectl get service github-mcp-service

Use MCP Inspector with external IP:

Connection Type: Select "HTTP/SSE"
Server URL: http://<EXTERNAL-IP> (use the IP from step 1)
Click "Connect"



MCP Inspector Testing Features
Once connected, you can use MCP Inspector to:

Explore Available Tools: View all GitHub operations your MCP server supports
Test Tool Calls: Execute GitHub API operations directly from the web interface
View Responses: See real-time responses and debug any issues
Resource Management: Test resource discovery and access
Protocol Debugging: Monitor MCP protocol messages and SSE events

Example Test Scenarios
Use MCP Inspector to test common GitHub operations:

List Repositories:

Tool: github_list_repos
Parameters: {"owner": "your-github-username"}


Get Repository Info:

Tool: github_get_repo
Parameters: {"owner": "owner-name", "repo": "repo-name"}


Search Issues:

Tool: github_search_issues
Parameters: {"query": "is:open label:bug"}


Create Issue (if your server supports it):

Tool: github_create_issue
Parameters: {"owner": "owner", "repo": "repo", "title": "Test Issue", "body": "Created via MCP Inspector"}



Monitoring and Logging
The server includes comprehensive logging and monitoring capabilities:

Structured Logging: JSON-formatted logs for easy parsing
Health Checks: Built-in health and readiness endpoints
Debug Mode: Detailed debugging information when enabled
Metrics: Ready for Prometheus integration

Viewing Logs
bash# Docker logs
docker logs container_name

# Kubernetes logs
kubectl logs deployment/github-mcp-server -f
Security Considerations

GitHub Token: Store securely using Kubernetes secrets
Network Policies: Implement appropriate network policies in GKE
Resource Limits: Set appropriate CPU and memory limits
Image Scanning: Regularly scan the image for vulnerabilities

Troubleshooting
Common Issues

Connection Refused: Check if the port 8080 is properly exposed
GitHub API Rate Limits: Ensure your GitHub token has sufficient permissions
Memory Issues: Increase memory limits if experiencing OOM kills

Debug Mode
Enable debug mode by setting environment variables:
bashdocker run -p 8080:8080 \
  -e GITHUB_TOKEN=your_token \
  -e LOG_LEVEL=debug \
  github-mcp-server
Health Checks
bash# Check server health
curl http://your-service-ip/health

# Check readiness
curl http://your-service-ip/ready
Contributing

Fork the repository
Create a feature branch
Make your changes
Test thoroughly
Submit a pull request

License
[Add your license information here]
Support
For issues and questions:

Create an issue in the GitHub repository
Check the troubleshooting section above
Review the logs for error messages
