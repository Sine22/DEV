FROM node:24-alpine AS deps
WORKDIR /usr/app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

FROM node:24-alpine
WORKDIR /usr/app
COPY index.js index.js
COPY --from=deps /usr/app/node_modules ./node_modules
EXPOSE 4444
CMD ["node", "index.js"]
