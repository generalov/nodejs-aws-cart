########################################
## Development
########################################
FROM node:12.20-buster as development
ENV NODE_ENV=development
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn --dev install
COPY . .
RUN yarn build

########################################
## Build
########################################
FROM node:12.20.0-alpine3.9 as build
RUN apk add --no-cache binutils && \
  strip /usr/local/bin/node
ENV NODE_ENV=production
WORKDIR /app/build/
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY --from=development /app/dist ./dist/
RUN find ./ -name '.gitignore' \
    -o -name LICENSE \
    -o -name '*.lock' \
    -o -name '*.log' \
    -o -name '*.map' \
    -o -name '*.markdown' \
    -o -name '*.md' \
    -o -name '*.spec.*' \
    -o -name '*.test.*' \
    -o -name '*.ts' \
    -o -name '*.tsbuildinfo' \
    -o -name '*.txt' \
    -o -name '.*.json' \
    -o -name '.*.yml' \
    -o -name '.*rc' \
    -o -name '.editorconfig' \
    -o -name '.eslint*' \
    -o -name '.npm*' \
    -o -name '.yarn*' \
    -o -name '@types' \
    -o -name 'Makefile' \
    -o -name 'karma.*' \
    -o -name 'test' \
    -o -name 'tests' \
    -o -name '__*__' \
    -o -path '*/rxjs/_*' \
    -o -path '*/rxjs/src/*' \
    -o -path '*/rxjs/testing/*' \
    -o -path '*/tslib/tslib*.html' \
    | xargs -n10 rm -rf

########################################
## Tiny NodeJS
########################################
FROM alpine:3.9 as node-tiny
ENV NODE_ENV=production
ENV NODE_VERSION 12.20.0
RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && rm -f /etc/*- \
    && apk add --no-cache libstdc++
COPY --from=build /usr/local/bin/docker-entrypoint.sh /usr/local/bin/node /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

########################################
## Production
########################################
FROM node-tiny as production
WORKDIR /app
COPY --from=build /app/build ./
USER node
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/main"]