# -------- Build Stage --------
# Use official Node.js LTS Alpine image
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files first for better Docker caching
COPY package*.json ./

# Install dependencies with legacy peer deps support
RUN npm install --legacy-peer-deps

# Copy application source code
COPY . .

# Skip React preflight dependency checks
ENV SKIP_PREFLIGHT_CHECK=true

# Build React application
RUN npm run build

# -------- Production Stage --------
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy all files from builder stage
COPY --from=builder /app .

# Expose application port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
