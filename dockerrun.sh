#!/usr/bin/env bash
#

set -e

SITENAME="${SITENAME:-test.localhostaspen}"

service cron start

./usr/local/aspen-discovery/install/setup_aspen_user_debian.sh

mkdir -p /data/aspen-discovery/${SITENAME}/covers/{small,large,medium,original}
mkdir -p /data/aspen-discovery/${SITENAME}/solr7
mkdir -p /data/aspen-discovery/${SITENAME}/ils/{marc,marc_delta,marc_recs,supplemental}

mkdir -p /usr/local/aspen-discovery/tmp/smarty/compile/

mkdir -p /var/log/aspen-discovery/${SITENAME}

chmod -R a+wr /var/log/

chmod -R a+wr /usr/local/aspen-discovery/ 2>/dev/null || true

chmod -R a+wr /data/aspen-discovery/${SITENAME}/

chown -R aspen /data/aspen-discovery/${SITENAME}/solr7

mkdir -p /var/run/aspen/
chown -R aspen:aspen /var/run/aspen/

echo "Generating Apache configuration from template..."
bash /generate-apache-config.sh

echo "Configuring PHP-FPM to listen on TCP port 9000..."
cat > /etc/php/8.4/fpm/pool.d/www.conf <<'EOF'
[www]
user = www-data
group = www-data
listen = 127.0.0.1:9000
pm = dynamic
pm.max_children = 6
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 5
chdir = /usr/local/aspen-discovery/code/web
request_terminate_timeout = 300
catch_workers_output = yes
php_admin_value[memory_limit] = 512M
php_admin_value[max_execution_time] = 300
EOF

echo "Enabling Apache modules for PHP-FPM..."
a2enmod proxy_fcgi setenvif rewrite

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

curl -k http://localhost/API/SystemAPI?method=runPendingDatabaseUpdates

crontab /etc/cron.d/cron

/bin/bash -c "trap : TERM INT; sleep infinity & wait"
