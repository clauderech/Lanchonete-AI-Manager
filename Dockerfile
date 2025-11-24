# Multi-stage build para otimizar o tamanho da imagem

# Stage 1: Build da aplicação React
FROM node:20-alpine AS frontend-build
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./
RUN npm ci

# Copiar código fonte
COPY . .

# Build da aplicação
ARG GEMINI_API_KEY
ENV GEMINI_API_KEY=$GEMINI_API_KEY
RUN npm run build

# Stage 2: Setup do backend
FROM node:20-alpine AS backend-setup
WORKDIR /app/backend

# Instalar dependências do backend
RUN npm init -y && \
    npm install express mysql2 cors body-parser dotenv pm2 -g

# Copiar server.js
COPY server.js .

# Stage 3: Imagem de produção
FROM node:20-alpine
WORKDIR /app

# Instalar PM2 globalmente
RUN npm install -g pm2

# Copiar build do frontend
COPY --from=frontend-build /app/dist ./dist

# Copiar backend
COPY --from=backend-setup /app/backend/node_modules ./node_modules
COPY server.js .
COPY ecosystem.config.js .

# Instalar serve para servir o frontend
RUN npm install -g serve

# Expor portas
EXPOSE 3000 3001

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Iniciar com PM2
CMD ["pm2-runtime", "start", "ecosystem.config.js"]
