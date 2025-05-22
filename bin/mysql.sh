#!/bin/sh
docker exec -it aspen-db mariadb -u root -paspen aspen "$@"
