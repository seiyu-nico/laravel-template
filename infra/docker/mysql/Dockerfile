FROM mysql:8.0

ENV TZ=UTC

ARG UID
ARG GID

ENV UID ${UID}
ENV GID ${GID}
RUN groupmod -g ${GID} mysql && \
    usermod -u ${UID} -g ${GID} mysql
COPY ./infra/docker/mysql/my.cnf /etc/my.cnf
