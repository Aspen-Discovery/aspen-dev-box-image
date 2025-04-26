#!/usr/bin/env bash
#

# This script is used to run the docker container
# cp -R /test.localhostaspen /usr/local/aspen-discovery/sites

service cron start

./usr/local/aspen-discovery/install/setup_aspen_user_debian.sh

mkdir -p /data/aspen-discovery/test.localhostaspen/covers/{small,large,medium,original}
mkdir -p /data/aspen-discovery/test.localhostaspen/solr7
mkdir -p /data/aspen-discovery/test.localhostaspen/ils/{marc,marc_delta,marc_recs,supplemental}

mkdir -p /usr/local/aspen-discovery/tmp/smarty/compile/

mkdir -p /var/log/aspen-discovery/test.localhostaspen

chmod -R a+wr /var/log/

chmod -R a+wr /usr/local/aspen-discovery/

chmod -R a+wr /data/aspen-discovery/test.localhostaspen/

chown -R aspen /data/aspen-discovery/test.localhostaspen/solr7

service apache2 start

curl -k http://localhost/API/SystemAPI?method=runPendingDatabaseUpdates

crontab /etc/cron.d/cron

/bin/bash -c "trap : TERM INT; sleep infinity & wait"
