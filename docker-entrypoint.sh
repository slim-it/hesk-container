#!/usr/bin/env sh
set -eu

install -d -o www-data -g www-data /data /data/attachments /data/cache

if [ ! -e /data/hesk_settings.inc.php ]; then
  cp /usr/local/share/hesk-defaults/hesk_settings.inc.php /data/hesk_settings.inc.php
fi

if [ "${HESK_ENABLE_INSTALL:-0}" = "1" ]; then
  rm -rf /var/www/html/install
  cp -a /usr/local/share/hesk-install /var/www/html/install
  chown -R www-data:www-data /var/www/html/install
else
  rm -rf /var/www/html/install
fi

chown -R www-data:www-data /data
chmod 0640 /data/hesk_settings.inc.php || true

exec "$@"
