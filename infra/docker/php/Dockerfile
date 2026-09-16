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

# Production stage
FROM base AS prod

# Copy PHP configuration
COPY ./infra/docker/php/php.ini/php.prod.ini /usr/local/etc/php/conf.d/custom.ini

# Development stage
FROM base AS dev

# Copy PHP configuration
COPY ./infra/docker/php/php.ini/php.dev.ini /usr/local/etc/php/conf.d/custom.ini

# Local stage with PCOV (coverage driver for Pest)
FROM base AS local

RUN install-php-extensions pcov

# Copy PHP configuration
COPY ./infra/docker/php/php.ini/php.local.ini /usr/local/etc/php/conf.d/custom.ini
