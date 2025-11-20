# Multi-stage build for optimized production image
FROM composer:latest AS composer-base

# Build stage for dependencies
FROM dunglas/frankenphp:1-php8.3 AS builder
LABEL maintainer="PyRowMan"
ARG MYSQL_CLIENT="mariadb-client"
ARG SEVENZIP_VERSION=2407

WORKDIR /app

# Copy composer from official image
COPY --from=composer-base --link /usr/bin/composer /usr/bin/composer

# Install system dependencies
RUN apt update \
 && apt install -y --no-install-recommends \
      unrar-free 7zip lame libcap2-bin python3 gettext-base \
      curl zip unzip git wget \
      gnupg libpng-dev libonig-dev libxml2-dev libicu-dev \
      libjpeg-dev libfreetype6-dev libxslt-dev $MYSQL_CLIENT libcurl4-openssl-dev \
 && wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-24_all.deb \
 && dpkg -i repo-mediaarea_1.0-24_all.deb \
 && apt update \
 && apt install -y libmediainfo0v5 mediainfo libzen0v5 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* repo-mediaarea_1.0-24_all.deb

# Install PHP extensions
RUN install-php-extensions imagick/imagick@master
RUN docker-php-ext-install \
      bcmath \
      exif \
      gd \
      intl \
      pdo_mysql \
      sockets \
      pcntl \
 && pecl install redis \
 && docker-php-ext-enable redis

# Copy only composer files first for better caching
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Production stage
FROM dunglas/frankenphp:1-php8.3
LABEL maintainer="PyRowMan"
ENV SERVER_NAME=:${APP_PORT:-80}
ARG MYSQL_CLIENT="mariadb-client"
ARG SEVENZIP_VERSION=2407

WORKDIR /app

# Copy Node.js for asset building
COPY --from=node:21 /usr/local/ /usr/local/

# Install only runtime dependencies
RUN apt update \
 && apt install -y --no-install-recommends \
      unrar-free lame python3 gettext-base \
      curl wget tmux fonts-powerline \
      ffmpeg jpegoptim webp optipng pngquant libavif-bin \
      $MYSQL_CLIENT \
 && wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-24_all.deb \
 && dpkg -i repo-mediaarea_1.0-24_all.deb \
 && apt update \
 && apt install -y libmediainfo0v5 mediainfo libzen0v5 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* repo-mediaarea_1.0-24_all.deb

# Install PHP extensions
RUN install-php-extensions imagick/imagick@master
RUN docker-php-ext-install \
      bcmath \
      exif \
      gd \
      intl \
      pdo_mysql \
      sockets \
      pcntl \
 && pecl install redis \
 && docker-php-ext-enable redis

# Install 7-Zip
RUN ARCH="$(dpkg --print-architecture)" && \
    if [ "$ARCH" = "amd64" ]; then \
        SZIP_URL="https://www.7-zip.org/a/7z$SEVENZIP_VERSION-linux-x64.tar.xz"; \
    fi && \
    if [ "$ARCH" = "arm64" ]; then \
        SZIP_URL="https://www.7-zip.org/a/7z$SEVENZIP_VERSION-linux-arm64.tar.xz"; \
    fi && \
    wget "$SZIP_URL" -O /tmp/7z.tar.xz && \
    tar -xf /tmp/7z.tar.xz -C /tmp/ && \
    mv /tmp/7zz /usr/bin/7zz && \
    rm -f /tmp/7z.tar.xz /tmp/7zzs

# Copy PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY ./docker/8.3/php.ini "$PHP_INI_DIR/conf.d/custom-conf.ini"

# Copy entrypoint
COPY --chmod=755 ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Copy application files
COPY --chown=www-data:www-data . /app

# Copy vendor from builder stage
COPY --from=builder --chown=www-data:www-data /app/vendor /app/vendor

# Remove unnecessary files
RUN rm -Rf tests/

# Set proper permissions
RUN chmod -R 755 /app/vendor/ \
 && chmod -R 777 /app/storage/ /app/resources/ /app/public/

EXPOSE ${APP_PORT:-80}

CMD ["--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
ENTRYPOINT ["docker-entrypoint"]
