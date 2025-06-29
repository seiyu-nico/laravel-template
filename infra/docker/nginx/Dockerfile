FROM nginx:1.29.0-alpine

WORKDIR /data

ENV TZ=UTC

COPY ./infra/docker/nginx/*.conf /etc/nginx/conf.d/
