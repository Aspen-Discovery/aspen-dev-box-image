#!/bin/bash
#
# start_evergreen_export.sh -
#
#       start evergreen_export.jar but make sure there is only one instance running

test -w /var/run/aspen || { echo "/var/run/aspen not writable"; exit 1; }

LOCKFILE=/var/run/aspen/evergreen_export.lock

cd /usr/local/aspen-discovery/code/evergreen_export
flock -n $LOCKFILE java -jar evergreen_export.jar test.localhostaspen || exit 1
