FROM node:12.13-buster as development

ENV NODE_ENV=development

WORKDIR /app

COPY package.json ./
COPY yarn.lock ./
RUN yarn --dev install

COPY . .
RUN yarn build

# seperate build for production
FROM node:12.13-alpine as production

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /app

COPY package*.json ./
RUN npm install --only=production

COPY . .
COPY --from=development /app/dist ./dist

USER node
ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/main"]