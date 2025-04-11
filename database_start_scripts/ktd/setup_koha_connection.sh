#!/usr/bin/env bash

# Wait for MySQL to be ready
until mariadb -u root -paspen -e "SELECT 1" >/dev/null 2>&1; do
    echo "Waiting for MySQL to be ready..."
    sleep 1
done

# Get the stack name from environment variable
KOHA_STACK=${KOHA_STACK:-kohadev}

# Insert the dynamic Koha connection details
mariadb -u root -paspen aspen << EOF
INSERT INTO account_profiles(
    id,
    name,
    driver,
    loginConfiguration,
    authenticationMethod,
    vendorOpacUrl,
    patronApiUrl,
    recordSource,
    weight,
    databaseHost,
    databaseName,
    databaseUser,
    databasePassword,
    sipHost,
    sipPort,
    sipUser,
    sipPassword,
    databasePort,
    databaseTimezone,
    oAuthClientId,
    oAuthClientSecret,
    ils,
    apiVersion,
    staffUsername,
    staffPassword,
    workstationId,
    domain
) VALUES(
    2,
    'ils',
    'Koha',
    'barcode_pin',
    'ils',
    'http://${KOHA_STACK}-koha-1:8080',
    'http://${KOHA_STACK}-koha-1:8080',
    'ils',
    1,
    '${KOHA_STACK}-db-1',
    'koha_kohadev',
    'koha_kohadev',
    'password',
    NULL,
    NULL,
    NULL,
    NULL,
    3306,
    'GMT',
    NULL,
    NULL,
    'koha',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
);
EOF

echo "Configured Koha connection for stack: ${KOHA_STACK}" 