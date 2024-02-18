FROM golang:buster as api_build

WORKDIR /build
COPY pastebin1s-api/go.mod .
COPY pastebin1s-api/go.sum .
RUN go mod download
COPY pastebin1s-api/Makefile Makefile
COPY pastebin1s-api/main.go main.go
RUN make compile

# build environment
FROM node:lts as web_build
WORKDIR /app

# Add container
# ENV PATH /app/node_modules/.bin:$PATH

COPY pastebin1s-frontend/package.json ./
COPY pastebin1s-frontend/package-lock.json ./
RUN npm ci --silent
COPY pastebin1s-frontend/ ./
RUN npm run build

# production environment
FROM nginx:stable-alpine

# API Component
WORKDIR /root/app
COPY --from=api_build /build/out .
COPY nginx/api.sh /docker-entrypoint.d/api.sh
RUN chmod +x /root/app/p1s-api
RUN chmod +x /docker-entrypoint.d/api.sh

# Website Component
COPY --from=web_build /app/build /usr/share/nginx/html
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# ENTRYPOINT ["nginx", "-g", "daemon off;"]
