FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --production || yarn install --production || pnpm install --prod || true
COPY . .
EXPOSE 4000
CMD ["npm","start"]
