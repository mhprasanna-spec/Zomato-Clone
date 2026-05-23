# ---- Build Stage ----
FROM node:18-alpine AS builder
WORKDIR /app

# Copy package files first (Docker cache optimization)
COPY package*.json ./

# Install ALL deps including devDependencies (needed for react-scripts build)
RUN npm ci

# Copy source code
COPY . .

# Build the production React bundle
RUN npm run build

# ---- Production Stage ----
FROM node:18-alpine
WORKDIR /app

# Copy package files for serve
COPY package*.json ./

# Install ONLY production dependencies in final image
RUN npm ci --only=production

# Copy built files from builder stage
COPY --from=builder /app/build ./build

EXPOSE 3000

# Use 'serve' to serve the static build, or keep npm start
CMD ["npm", "start"]
