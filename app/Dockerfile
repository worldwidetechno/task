# --- Build Stage ---
FROM node:18-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --silent
COPY . .
# API_URL injected at build time via build arg, written into config.json
ARG API_URL=http://localhost:8080
RUN echo "{\"apiUrl\":\"${API_URL}\"}" > src/config.json && npm run build

# --- Runtime Stage ---
FROM nginx:1.25-alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
