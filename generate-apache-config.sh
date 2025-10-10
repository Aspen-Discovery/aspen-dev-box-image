#!/usr/bin/env bash

set -e

SITENAME="${SITENAME:-test.localhostaspen}"
SERVERNAME="${SERVERNAME:-localhost:80}"
CONFIG_DIR="/usr/local/aspen-discovery/sites/${SITENAME}"
PHP_FPM_HOST="${PHP_FPM_HOST:-127.0.0.1}"
PHP_FPM_PORT="${PHP_FPM_PORT:-9000}"

TEMPLATE_DIR="/usr/local/aspen-discovery/sites/template.linux"
TEMPLATE_FILE="$TEMPLATE_DIR/httpd-{sitename}.conf"
OUTPUT_FILE="/etc/apache2/sites-enabled/httpd-${SITENAME}.conf"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

echo "Generating Apache configuration for site: $SITENAME"
echo "Using template: $TEMPLATE_FILE"
echo "Output file: $OUTPUT_FILE"

mkdir -p "${CONFIG_DIR}/conf"

echo "Copying configuration files from template..."
cp -n "$TEMPLATE_DIR/conf/badBotsLocal.conf" "${CONFIG_DIR}/conf/badBotsLocal.conf" 2>/dev/null || true

sed -e "s#{sitename}#${SITENAME}#g" \
    -e "s#{servername}#${SERVERNAME}#g" \
    -e "s#{configDir}#${CONFIG_DIR}#g" \
    -e "s#{phpFpmHost}#${PHP_FPM_HOST}#g" \
    -e "s#{phpFpmPort}#${PHP_FPM_PORT}#g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Apache configuration generated successfully at $OUTPUT_FILE"
