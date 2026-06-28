FROM php:8.3-apache-bookworm

ARG HESK_VERSION
LABEL org.opencontainers.image.title="Hesk container"
LABEL org.opencontainers.image.description="Hesk help desk on PHP Apache"
LABEL org.opencontainers.image.source="https://github.com/slim-it/hesk-container"
LABEL org.opencontainers.image.version="${HESK_VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd mysqli pdo_mysql zip \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/download-hesk.sh /usr/local/bin/download-hesk
RUN test -n "${HESK_VERSION}" \
    && chmod +x /usr/local/bin/download-hesk \
    && rm -rf /var/www/html/* \
    && mkdir -p /usr/local/share/hesk-defaults /usr/local/share/hesk-install /usr/local/share/hesk-language-defaults \
    && download-hesk "${HESK_VERSION}" /tmp/hesk.zip \
    && unzip -q /tmp/hesk.zip -d /var/www/html \
    && cp /var/www/html/hesk_settings.inc.php /usr/local/share/hesk-defaults/hesk_settings.inc.php \
    && cp -a /var/www/html/install/. /usr/local/share/hesk-install/ \
    && cp -a /var/www/html/language/. /usr/local/share/hesk-language-defaults/ \
    && rm -rf /tmp/hesk.zip /var/www/html/attachments /var/www/html/hesk_settings.inc.php /var/www/html/install /var/www/html/language \
    && ln -s /data/attachments /var/www/html/attachments \
    && ln -s /data/language /var/www/html/language \
    && ln -s /data/hesk_settings.inc.php /var/www/html/hesk_settings.inc.php \
    && chown -R www-data:www-data /var/www/html /usr/local/share/hesk-defaults /usr/local/share/hesk-install /usr/local/share/hesk-language-defaults

COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY php.ini /usr/local/etc/php/conf.d/zz-hesk.ini
COPY docker-entrypoint.sh /usr/local/bin/hesk-entrypoint
RUN chmod +x /usr/local/bin/hesk-entrypoint

VOLUME ["/data"]
ENTRYPOINT ["hesk-entrypoint"]
CMD ["apache2-foreground"]
