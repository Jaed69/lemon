# lemon

Astro static site served by nginx on port 8080, deployed to `lemon.luciel.dev`.

Split out of the `luciel-platform` monorepo; its git history came with it.

## Develop

```sh
pnpm install
pnpm dev
```

## Build the image locally

```sh
docker build -t lemon .
docker run --rm -p 8080:8080 lemon
```

## Deploy

Push to `main`. CI builds the arm64 image, pushes `ghcr.io/jaed69/lemon:sha-<7>`, scans it
with Trivy, promotes it to `latest`, then records `LEMON_TAG` in
[`Jaed69/luciel-platform`](https://github.com/Jaed69/luciel-platform) `env/tags.env`.
That commit is what triggers the deploy to the VPS.

Routing, TLS and the container's place in the stack are declared in the deployment repo's
`docker-compose.yml` and `traefik/` — not here.

To roll back one release, revert the `chore(deploy): LEMON_TAG=...` commit in the
deployment repo.
