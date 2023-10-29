FROM nginx:1.25.3-alpine

WORKDIR /data

ENV TZ=UTC

COPY ./infra/docker/nginx/*.conf /etc/nginx/conf.d/
