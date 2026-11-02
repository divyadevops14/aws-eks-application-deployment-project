# Small base image keeps the push to ECR fast and cheap
FROM node:22-alpine

WORKDIR /app

# Copy package.json first so Docker can cache this layer
COPY package.json ./

# The app has no dependencies, but this keeps the Dockerfile ready if you add some later
RUN npm install --omit=dev --no-audit --no-fund

COPY server.js ./

ENV PORT=3000
EXPOSE 3000

# Run as the non-root user that ships with the node image
USER node

CMD ["node", "server.js"]
