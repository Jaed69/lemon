# syntax=docker/dockerfile:1
# Multi-stage: node build -> nginx runtime. Build context is this repo root:
#   docker build -t lemon .
FROM node:26.12.1-slim AS build
ENV PNPM_CONFIG_STRICT_DEP_BUILDS=false \
    pnpm_config_store_dir=/pnpm/store
WORKDIR /app
# Node 26 no longer bundles corepack: install the pnpm pinned in package.json (packageManager) via npm.
RUN npm install -g pnpm@12.16.1
# Settings pnpm reads from pnpm-workspace.yaml (build-script allowlist, overrides) are
# needed at install time, so the file is copied with the manifests.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
# Download deps from the lockfile alone (cached layer + BuildKit store cache at /pnpm/store,
# set via pnpm_config_store_dir: pnpm ignores npm_config_store_dir), then link them.
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm fetch
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --prefer-offline
COPY . .
RUN pnpm build

FROM nginx:1.31.8-alpine AS runtime
# CVE-2026-111497: the base image ships brotli-libs 1.2.0-r1. Drop once the base tag includes 1.2.1.
RUN apk upgrade --no-cache brotli-libs
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
