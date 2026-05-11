# --- Fase 1: Dependencias ---
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install

# --- Fase 2: Runner (Producción e Integración) ---
FROM node:18-alpine AS runner
WORKDIR /app

# Copiamos dependencias y código
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Fix de permisos: Creamos coverage y damos propiedad al usuario node
RUN mkdir -p /app/coverage && \
    chown -R node:node /app && \
    chmod -R 755 /app

ENV NODE_ENV=production
ENV PORT=3000

# Seguridad: No correr como root
USER node
EXPOSE 3000

CMD ["npm", "start"]