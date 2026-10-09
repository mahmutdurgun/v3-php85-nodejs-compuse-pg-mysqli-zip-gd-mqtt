FROM node:24-bookworm-slim AS node
FROM php:8.5-apache-bookworm
COPY --from=node /usr/local/ /usr/local/
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server supervisor nano curl wget git unzip zip ca-certificates \
    acl python3 procps iproute2 netcat-openbsd mosquitto-clients \
    default-mysql-client postgresql-client build-essential \
    libjpeg62-turbo-dev libpng-dev libfreetype6-dev libwebp-dev \
    libzip-dev libicu-dev libpq-dev libonig-dev libcurl4-openssl-dev libsqlite3-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" gd mysqli pdo_mysql pgsql pdo_pgsql \
       pdo_sqlite zip intl mbstring bcmath sockets pcntl exif curl \
    && pecl install redis && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash -G www-data mahmut \
    && echo 'mahmut:1234' | chpasswd \
    && a2enmod rewrite headers expires proxy proxy_http proxy_wstunnel \
    && mkdir -p /run/sshd /opt/php-tools /opt/examples \
    && printf 'PermitRootLogin no\nPasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/mahmut.conf
COPY tools-composer.json /opt/php-tools/composer.json
RUN cd /opt/php-tools && COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --prefer-dist --no-interaction
COPY custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY apache-health.conf /etc/apache2/conf-enabled/container-health.conf
COPY welcome.php /opt/examples/welcome.php
COPY health.php /opt/container-health/index.php
COPY apache-site.conf /etc/apache2/sites-available/000-default.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /usr/local/bin/web-entrypoint
COPY examples/ /opt/examples/
RUN chmod +x /usr/local/bin/web-entrypoint
ENV COMPOSER_ALLOW_SUPERUSER=1
WORKDIR /var/www/html
EXPOSE 80 22
ENTRYPOINT ["web-entrypoint"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
