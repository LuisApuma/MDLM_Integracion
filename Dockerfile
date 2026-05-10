# --- Fase 1: Dependencias (Instalamos todo para poder testear) ---
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install

# --- Fase 2: Test (Opcional pero útil para validación interna) ---
FROM deps AS tester
COPY . .
# Aquí podrías correr tests internos si quisieras

# --- Fase 3: Producción (Solo lo mínimo indispensable) ---
FROM node:18-alpine AS runner
WORKDIR /app
# Copiamos las dependencias de deps (que incluye sequelize-cli para las migraciones)
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NODE_ENV=production
ENV PORT=3000

USER node
EXPOSE 3000
CMD ["npm", "start"]
