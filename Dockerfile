FROM php:8.5.11-fpm-trixie

ARG HESK_VERSION
LABEL org.opencontainers.image.title="Hesk container"
LABEL org.opencontainers.image.description="Hesk help desk on PHP-FPM"
LABEL org.opencontainers.image.source="https://github.com/slim-it/hesk-container"
# Not org.opencontainers.image.version: CI overwrites that annotation
# with the tag.
LABEL nl.slim-it.hesk.version="${HESK_VERSION}"

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
    && rm -rf /var/lib/apt/lists/*

# The application lives in /usr/src/hesk and the entrypoint copies it into the
# web root at every start, so a web root shared with a web server container
# always holds exactly the code this image ships.
COPY scripts/download-hesk.sh /usr/local/bin/download-hesk
RUN test -n "${HESK_VERSION}" \
    && chmod +x /usr/local/bin/download-hesk \
    && mkdir -p /usr/src/hesk /usr/local/share/hesk-defaults /usr/local/share/hesk-install /usr/local/share/hesk-language-defaults \
    && download-hesk "${HESK_VERSION}" /tmp/hesk.zip \
    && unzip -q /tmp/hesk.zip -d /usr/src/hesk \
    && cp /usr/src/hesk/hesk_settings.inc.php /usr/local/share/hesk-defaults/hesk_settings.inc.php \
    && cp -a /usr/src/hesk/install/. /usr/local/share/hesk-install/ \
    && cp -a /usr/src/hesk/language/. /usr/local/share/hesk-language-defaults/ \
    && rm -rf /tmp/hesk.zip /usr/src/hesk/attachments /usr/src/hesk/hesk_settings.inc.php /usr/src/hesk/install /usr/src/hesk/language \
    && ln -s /data/attachments /usr/src/hesk/attachments \
    && ln -s /data/language /usr/src/hesk/language \
    && ln -s /data/hesk_settings.inc.php /usr/src/hesk/hesk_settings.inc.php \
    && rm -rf /var/www/html/* \
    && mkdir -p /data \
    && chown -R www-data:www-data /data /var/www/html /usr/src/hesk /usr/local/share/hesk-defaults /usr/local/share/hesk-install /usr/local/share/hesk-language-defaults

COPY php.ini /usr/local/etc/php/conf.d/zz-hesk.ini
COPY docker-entrypoint.sh /usr/local/bin/hesk-entrypoint
RUN chmod +x /usr/local/bin/hesk-entrypoint

# Numeric, so a runtime that requires a non-root user can verify it.
USER 33:33
VOLUME ["/data"]
ENTRYPOINT ["hesk-entrypoint"]
CMD ["php-fpm"]
