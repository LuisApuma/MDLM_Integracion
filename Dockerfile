# --- Fase 1: Dependencias ---
FROM node:18.19-alpine AS deps
# Actualizamos el SO para corregir vulnerabilidades críticas (CVEs)
RUN apk update && apk upgrade --no-cache
WORKDIR /app
COPY package*.json ./
RUN npm install

# --- Fase 2: Runner ---
FROM node:18.19-alpine AS runner
# También actualizamos la imagen final
RUN apk update && apk upgrade --no-cache
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Fix de permisos para SonarQube y Seguridad
RUN mkdir -p /app/coverage && \
    chown -R node:node /app && \
    chmod -R 755 /app

ENV NODE_ENV=production
ENV PORT=3000

USER node
EXPOSE 3000

CMD ["npm", "start"]
