FROM dunglas/frankenphp:1-php8.4-bookworm AS base

WORKDIR /app

ARG ENV

# timezone environment
ENV TZ=UTC \
    # locale
    LANG=ja_JP.UTF-8 \
    # composer environment
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer

COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Install system dependencies and PHP extensions
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    locales \
    git \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 ja_JP.UTF-8 \
    && localedef -f UTF-8 -i en_US en_US.UTF-8 \
    && install-php-extensions \
    intl \
    pdo_mysql \
    zip \
    bcmath \
    opcache \
    pcntl

ARG UID
ARG GID
ENV UID=${UID}
ENV GID=${GID}
ENV USER=dev

RUN groupadd --force -g ${GID} ${USER} && \
    useradd -ms /bin/bash --no-user-group -u ${UID} -g ${GID} ${USER} && \
    mkdir -p /composer && \
    mkdir -p /data/caddy && \
    mkdir -p /config/caddy && \
    chown -R ${USER}:${USER} /app && \
    chown -R ${USER}:${USER} /composer && \
    chown -R ${USER}:${USER} /data/caddy && \
    chown -R ${USER}:${USER} /config/caddy

# Production stage
FROM base AS prod

# Copy PHP configuration
COPY --chown=${USER}:${USER} ./infra/docker/php/php.ini/php.prod.ini /usr/local/etc/php/conf.d/custom.ini

USER ${USER}

# Development stage
FROM base AS dev

# Copy PHP configuration
COPY --chown=${USER}:${USER} ./infra/docker/php/php.ini/php.dev.ini /usr/local/etc/php/conf.d/custom.ini

USER ${USER}

# Local stage with Xdebug
FROM base AS local

RUN install-php-extensions xdebug

# Copy PHP configuration
COPY --chown=${USER}:${USER} ./infra/docker/php/php.ini/php.local.ini /usr/local/etc/php/conf.d/custom.ini

USER ${USER}
