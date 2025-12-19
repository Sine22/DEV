FROM node:24-alpine
WORKDIR /usr/app
COPY package.json .
RUN npm install --omit=dev
COPY index.js .
EXPOSE 4444
CMD ["node", "index.js"]
