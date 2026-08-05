#!/usr/bin/env bash
#

set -e
source /container_setup.sh

ensure_composer

SITENAME="${SITE_NAME:-test.localhostaspen}"
LOCAL_USER_ID="${LOCAL_USER_ID:-501}"
LOCAL_GROUP_ID="${LOCAL_GROUP_ID:-20}"
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')

echo "Configuring container users to match host (UID=${LOCAL_USER_ID}, GID=${LOCAL_GROUP_ID})..."

# Remap www-data group GID — PHP-FPM (group=www-data) and Apache (APACHE_RUN_GROUP)
# resolve this group name at runtime, so it must carry the host GID.
remap_www_data
getent group aspen_apache > /dev/null 2>&1 || groupadd -o -g "${LOCAL_GROUP_ID}" aspen_apache
usermod -a -G aspen_apache,sudo www-data

if ! id aspen > /dev/null 2>&1; then
    useradd -r -o -u "${LOCAL_USER_ID}" -g www-data -G aspen_apache -m -s /bin/bash aspen
else
    usermod -o -u "${LOCAL_USER_ID}" -g www-data aspen
fi

if ! id solr > /dev/null 2>&1; then
    useradd -r -o -u "${LOCAL_USER_ID}" -g www-data -M -s /bin/bash solr
else
    usermod -o -u "${LOCAL_USER_ID}" -g www-data solr
fi

echo "www-data ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/www-data

export CONFIG_DIRECTORY="/usr/local/aspen-discovery/sites/${SITENAME}"
create_site_config "${CONFIG_DIRECTORY}"

cd /usr/local/aspen-discovery/docker/files/scripts

echo "syncing env vars..."
php syncEnvToConfig.php || true

if [ "${ASPEN_PLUGINS_ENABLED:-0}" = "1" ]; then
    cat >> "${CONFIG_DIRECTORY}/conf/config.ini" <<'EOF'

[Plugins]
enabled = 1
path = /plugins
EOF
fi

echo "Initializing database..."
php initDatabase.php

echo "Setting up directories and service configs..."
mkdir -p /usr/local/aspen-discovery/tmp/smarty/compile
mkdir -p /data/aspen-discovery/${SITENAME}/{covers/{small,large,medium,original},solr7,ils/{marc,marc_delta,marc_recs,supplemental},uploads,files,fonts}
mkdir -p /var/log/aspen-discovery/${SITENAME}/logs
mkdir -p /var/run/aspen
chown -R www-data:www-data /usr/local/aspen-discovery/tmp /var/log/aspen-discovery /data/aspen-discovery/${SITENAME}
chown -R www-data:www-data "${CONFIG_DIRECTORY}"
chown -R aspen:www-data /var/run/aspen
cp "${CONFIG_DIRECTORY}/httpd-${SITENAME}.conf" /etc/apache2/sites-enabled/
cp "${CONFIG_DIRECTORY}/conf/php-fpm.conf" "/etc/php/${PHP_VERSION}/fpm/pool.d/"

echo "Running pending database updates..."
php updateDatabase.php "${SITENAME}"

crontab "${CONFIG_DIRECTORY}/conf/crontab"
service cron start

if [ -f /aspen-dev-conf/xdebug.ini ]; then
    if php -r 'exit(file_exists(ini_get("extension_dir") . "/xdebug.so") ? 0 : 1);'; then
        phpenmod xdebug
        ln -sf /aspen-dev-conf/xdebug.ini "/etc/php/${PHP_VERSION}/fpm/conf.d/99-xdebug.ini"
    else
        echo "WARNING: xdebug extension not present in this image, step debugging disabled"
    fi
fi

if [ -f /aspen-dev-conf/error_reporting.ini ]; then
    ln -sf /aspen-dev-conf/error_reporting.ini "/etc/php/${PHP_VERSION}/fpm/conf.d/error_reporting.ini"
fi

echo "Starting PHP-FPM..."
"php-fpm${PHP_VERSION}" &

echo "Waiting for PHP-FPM to be ready on port 9000..."
for i in {1..10}; do
    if nc -z 127.0.0.1 9000 2>/dev/null; then
        echo "PHP-FPM is ready"
        break
    fi
    sleep 1
done

echo "Starting Apache..."
service apache2 start

sudo -u www-data php /usr/local/aspen-discovery/docker/files/cron/checkBackgroundProcessesDocker.php "${SITENAME}" || true

cat <<EOF

========================================
  Aspen dev box ready
  URL:  http://localhost:${ASPEN_PORT:-8083}
  Site: ${SITENAME}
========================================

EOF

/bin/bash -c "trap : TERM INT; sleep infinity & wait"
