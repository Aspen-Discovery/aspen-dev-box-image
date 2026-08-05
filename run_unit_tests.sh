#!/usr/bin/env bash

set -e
source /container_setup.sh

SITENAME="unit_tests.localhost"

export SITE_NAME="${SITENAME}"
export URL="http://${SITENAME}"
export DATABASE_NAME="${TEST_DATABASE_NAME:-aspen_unit_tests}"
export CONFIG_DIRECTORY="/usr/local/aspen-discovery/sites/${SITENAME}"

echo "Preparing unit test environment..."
SETUP_LOG="$(mktemp)"
set +e
(
    set -e
    remap_www_data
    ensure_composer
    create_site_config "${CONFIG_DIRECTORY}"
    (cd /usr/local/aspen-discovery/docker/files/scripts && php syncEnvToConfig.php)

    if ! grep -q "^database_aspen_host" "${CONFIG_DIRECTORY}/conf/config.pwd.ini"; then
        sed -i "/^\[Database\]/a database_aspen_host     = ${DATABASE_HOST:-aspen-db}\ndatabase_aspen_dbport   = ${DATABASE_PORT:-3306}" "${CONFIG_DIRECTORY}/conf/config.pwd.ini"
    fi

    echo "Ensuring database ${DATABASE_NAME} exists..."
    mysql -h "${DATABASE_HOST:-aspen-db}" -P "${DATABASE_PORT:-3306}" -uroot -p"${DATABASE_ROOT_PASSWORD:-aspen}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${DATABASE_NAME}\`;
GRANT ALL PRIVILEGES ON \`${DATABASE_NAME}\`.* TO '${DATABASE_USER:-aspensuper}'@'%';
FLUSH PRIVILEGES;
SQL

    if ! mysql -h "${DATABASE_HOST:-aspen-db}" -P "${DATABASE_PORT:-3306}" -uroot -p"${DATABASE_ROOT_PASSWORD:-aspen}" -e "SELECT 1 FROM \`${DATABASE_NAME}\`.library LIMIT 1" > /dev/null 2>&1; then
        echo "Importing schema into ${DATABASE_NAME}..."
        mysql -h "${DATABASE_HOST:-aspen-db}" -P "${DATABASE_PORT:-3306}" -uroot -p"${DATABASE_ROOT_PASSWORD:-aspen}" "${DATABASE_NAME}" < /usr/local/aspen-discovery/install/aspen.sql
    fi

    mkdir -p /usr/local/aspen-discovery/tmp/smarty/compile
    mkdir -p "/var/log/aspen-discovery/${SITENAME}/logs"
    chown -R www-data:www-data "${CONFIG_DIRECTORY}" /var/log/aspen-discovery /usr/local/aspen-discovery/tmp
) > "${SETUP_LOG}" 2>&1
SETUP_STATUS=$?
set -e

if [ "${SETUP_STATUS}" -ne 0 ]; then
    cat "${SETUP_LOG}"
    exit "${SETUP_STATUS}"
fi

cd /usr/local/aspen-discovery/tests/phpunit
exec runuser -u www-data -- php phpunit.phar --testdox "$@"
