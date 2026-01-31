# Use Bun image
FROM oven/bun:1 AS builder
WORKDIR /app

# Copy root config files
COPY package.json bun.lock bunfig.toml ./

# Copy workspace package.json files to leverage Docker cache
COPY apps/viewer/package.json ./apps/viewer/
COPY apps/electron/package.json ./apps/electron/
COPY packages/core/package.json ./packages/core/
COPY packages/ui/package.json ./packages/ui/
COPY packages/mermaid/package.json ./packages/mermaid/
COPY packages/shared/package.json ./packages/shared/

# Create directory and copy preload script needed for bun lifecycle scripts
RUN mkdir -p packages/shared/src
COPY packages/shared/src/network-interceptor.ts ./packages/shared/src/

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the source code
COPY . .

# Build the viewer application
RUN bun run viewer:build

# Production stage
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/apps/viewer/dist /usr/share/nginx/html/s
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
