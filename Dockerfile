## Development ######################
FROM node:12.13-buster as development
ENV NODE_ENV=development
WORKDIR /app
COPY package.json ./
COPY yarn.lock ./
RUN yarn --dev install
COPY . .
RUN yarn build


## Production Build ##################
FROM node:12.20.0-alpine3.12 as production-build
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY --from=development /app/dist ./dist
RUN find . -name '.gitignore' \
    -o -name LICENSE \
    -o -name '*.md' \
    -o -name '*.d.ts' \
    -o -name '*.map' \
    -o -name '.*.yml' \
    -o -name '*.{test|spec}.*' \
    -o -name '{test|tests}' \
    -o -name '__*__' \
    | xargs -n1 rm -rf \
    && mkdir /app/build && mv package.json dist node_modules /app/build

## Production ######################
FROM alpine:3.10 as production
ENV NODE_VERSION 12.20.0
RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && apk add --no-cache libstdc++
COPY --from=production-build /usr/local/bin/docker-entrypoint.sh /usr/local/bin/node /usr/local/bin/
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENTRYPOINT ["docker-entrypoint.sh"]

WORKDIR /app
COPY --from=production-build /app/build ./
USER node
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/main"]