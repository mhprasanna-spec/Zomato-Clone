# -------- Build Stage --------
FROM node:16-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Skip CRA preflight checks
ENV SKIP_PREFLIGHT_CHECK=true

# Fix OpenSSL issue for old React/Webpack apps
ENV NODE_OPTIONS=--openssl-legacy-provider

# Build app
RUN npm run build

# -------- Production Stage --------
FROM node:16-alpine

# Set working directory
WORKDIR /app

# Copy files from builder
COPY --from=builder /app .

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
