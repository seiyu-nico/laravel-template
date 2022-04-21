FROM php:8.1-fpm-bullseye AS base

WORKDIR /src

# timezone environment
ENV TZ=UTC \
  # locale
  LANG=ja_JP.UTF-8 \
  # composer environment
  COMPOSER_ALLOW_SUPERUSER=1 \
  COMPOSER_HOME=/composer

COPY --from=composer:2.2 /usr/bin/composer /usr/bin/composer

RUN apt-get update \
  && apt-get -y install --no-install-recommends \
    locales \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libonig-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && locale-gen en_US.UTF-8 \
  && localedef -f UTF-8 -i en_US en_US.UTF-8 \
  && docker-php-ext-install \
    intl \
    pdo_mysql \
    zip \
    bcmath

COPY ./infra/docker/php/php.development.ini /usr/local/etc/php/php.ini

ARG UID
ARG GID
ENV UID ${UID}
ENV GID ${GID}
ENV USER dev

RUN groupadd --force -g ${GID} ${USER} && \
    useradd -ms /bin/bash --no-user-group -u ${UID} -g ${GID} ${USER} && \
    chown -R ${USER}:${USER} /src
USER ${USER}
