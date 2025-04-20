FROM nginx:1.27.5-alpine

WORKDIR /data

ENV TZ=UTC

COPY ./infra/docker/nginx/*.conf /etc/nginx/conf.d/
