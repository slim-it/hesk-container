#!/usr/bin/env sh
set -eu

install -d -o www-data -g www-data /data /data/attachments /data/language

if [ ! -e /data/hesk_settings.inc.php ]; then
  cp /usr/local/share/hesk-defaults/hesk_settings.inc.php /data/hesk_settings.inc.php
fi

if [ -z "$(find /data/language -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
  cp -a /usr/local/share/hesk-language-defaults/. /data/language/
fi

image_version="$(tr -d '\r' < /usr/local/share/hesk-install/install_functions.inc.php | awk -F"'" '/HESK_NEW_VERSION/ {print $4; exit}')"
installed_version="$(tr -d '\r' < /data/hesk_settings.inc.php | awk -F"'" '/hesk_version/ {print $4; exit}')"
install_mode="${HESK_INSTALL_MODE:-auto}"
expose_install=0

case "$install_mode" in
  enabled)
    expose_install=1
    ;;
  disabled)
    expose_install=0
    ;;
  auto)
    if [ -z "$installed_version" ]; then
      expose_install=1
    elif grep -Eq "\$hesk_settings\['db_host'\]='localhost';|\$hesk_settings\['db_user'\]='test';|\$hesk_settings\['db_pass'\]='test';" /data/hesk_settings.inc.php; then
      expose_install=1
    elif [ "$installed_version" != "$image_version" ]; then
      expose_install=1
    fi
    ;;
  *)
    echo "Invalid HESK_INSTALL_MODE: $install_mode" >&2
    echo "Expected one of: auto, enabled, disabled" >&2
    exit 1
    ;;
esac

rm -rf /var/www/html/install
if [ "$expose_install" = "1" ]; then
  cp -a /usr/local/share/hesk-install /var/www/html/install
  chown -R www-data:www-data /var/www/html/install
fi

chown -R www-data:www-data /data
chmod 0640 /data/hesk_settings.inc.php || true

exec "$@"
