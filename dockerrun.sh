#!/usr/bin/env bash
#

set -e

SITENAME="${SITENAME:-test.localhostaspen}"

service cron start

./usr/local/aspen-discovery/install/setup_aspen_user_debian.sh

mkdir -p /data/aspen-discovery/test.localhostaspen/covers/{small,large,medium,original}
mkdir -p /data/aspen-discovery/test.localhostaspen/solr7
mkdir -p /data/aspen-discovery/test.localhostaspen/ils/{marc,marc_delta,marc_recs,supplemental}

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
service apache2 start

curl -k http://localhost/API/SystemAPI?method=runPendingDatabaseUpdates

crontab /etc/cron.d/cron

/bin/bash -c "trap : TERM INT; sleep infinity & wait"
