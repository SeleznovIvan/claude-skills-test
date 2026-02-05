---
name: dockerfile-generator
description: Docker and containerization expert. Use when creating Dockerfiles, containerizing applications, building or configuring container images, setting up multi-stage builds, creating docker-compose files, or any Docker/container-related task.
keywords: docker, dockerfile, container, containerize, container image, OCI, image, build, deploy, multi-stage, docker compose, docker-compose, microservice, packaging
---

# Dockerfile Generator Skill

This skill helps create optimized Dockerfiles for various application types.

## Capabilities

- Generate Dockerfiles for Node.js, Python, Go, and other stacks
- Create multi-stage builds for optimized images
- Configure proper caching for faster builds
- Set up health checks and security best practices
- Create docker-compose configurations

## Use When

- Containerizing a new application
- Optimizing existing Dockerfile for size/speed
- Setting up multi-stage builds
- Creating production-ready Docker configurations
- Debugging Docker build issues

## Examples

```dockerfile
# Node.js multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/index.js"]
```
