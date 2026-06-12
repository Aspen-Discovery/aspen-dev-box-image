#!/usr/bin/env bash
#

set -e

SITENAME="${SITE_NAME:-test.localhostaspen}"
LOCAL_USER_ID="${LOCAL_USER_ID:-501}"
LOCAL_GROUP_ID="${LOCAL_GROUP_ID:-20}"

echo "Configuring container users to match host (UID=${LOCAL_USER_ID}, GID=${LOCAL_GROUP_ID})..."

# Remap www-data group GID — PHP-FPM (group=www-data) and Apache (APACHE_RUN_GROUP)
# resolve this group name at runtime, so it must carry the host GID.
groupmod -o -g "${LOCAL_GROUP_ID}" www-data
getent group aspen_apache > /dev/null 2>&1 || groupadd -o -g "${LOCAL_GROUP_ID}" aspen_apache
usermod -o -u "${LOCAL_USER_ID}" -s /bin/bash www-data
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
mkdir -p $CONFIG_DIRECTORY 2>/dev/null

cd /usr/local/aspen-discovery/docker/files/scripts

if [ ! -f "${CONFIG_DIRECTORY}/conf/config.ini" ]; then
    echo "Creating site configuration for ${SITENAME}..."
    php createConfig.php "${CONFIG_DIRECTORY}"
else
    echo "Site configuration exists..."
fi 
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
cp "${CONFIG_DIRECTORY}/conf/php-fpm.conf" /etc/php/8.4/fpm/pool.d/

echo "Running pending database updates..."
php updateDatabase.php "${SITENAME}"

crontab "${CONFIG_DIRECTORY}/conf/crontab"
service cron start

echo "Starting PHP-FPM..."
php-fpm8.4 &

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
