# -------- Build Stage --------
FROM node:16-bullseye AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Skip React dependency validation
ENV SKIP_PREFLIGHT_CHECK=true

# Build application
RUN npm run build

# -------- Production Stage --------
FROM node:16-bullseye

# Set working directory
WORKDIR /app

# Copy built app
COPY --from=builder /app .

# Expose app port
EXPOSE 3000

# Start app
CMD ["npm", "start"]
