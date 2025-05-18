#!/bin/sh
MARIADB_DATABASE=aspen
MARIADB_USER=aspensuper
MARIADB_PASSWORD=aspensuper

docker run -it --network aspen-net \
  --rm mariadb \
  mariadb \
  --host=aspen-db \
  --database=$MARIADB_DATABASE \
  --user=$MARIADB_USER \
  --password=$MARIADB_PASSWORD \
  "$@"
