# ── Build Stage ──────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev

# ── Production Stage ─────────────────────────────
FROM node:20-alpine AS production

ARG BUILD_NUMBER=unknown
ARG GIT_COMMIT=unknown

WORKDIR /app

# Non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder /app/node_modules ./node_modules
COPY src/ ./src/
COPY package*.json ./

ENV NODE_ENV=production
ENV PORT=8080

LABEL build.number="${BUILD_NUMBER}"
LABEL git.commit="${GIT_COMMIT}"

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "src/server.js"]
