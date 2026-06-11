#!/bin/sh
set -eu

SELF_ID=$(cat /etc/hostname)
PROJECT=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project"}}' "$SELF_ID")

DB_CONTAINER=$(docker ps -q \
  --filter "label=com.docker.compose.project=$PROJECT" \
  --filter "label=com.docker.compose.service=aspen-db" | head -n1)

KOHA_CONTAINER=$(docker ps -q \
  --filter "label=com.docker.compose.project=${KOHA_STACK:-kohadev}" \
  --filter "label=com.docker.compose.service=koha" | head -n1)

if [ -z "$DB_CONTAINER" ] || [ -z "$KOHA_CONTAINER" ]; then
  echo "koha-oauth: could not locate containers (db=$DB_CONTAINER koha=$KOHA_CONTAINER)" >&2
  exit 1
fi

EXISTING=$(docker exec "$DB_CONTAINER" mariadb -uroot -paspen aspen -sN -e \
  "SELECT IFNULL(oAuthClientId,'') FROM account_profiles WHERE id=2;")

if [ -n "$EXISTING" ]; then
  echo "koha-oauth: keys already present, skipping"
  exit 0
fi

DEADLINE=$(($(date +%s) + 300))

while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if docker exec "$KOHA_CONTAINER" test -f /ktd_ready 2>/dev/null; then
    break
  fi
  echo "koha-oauth: waiting for ktd readiness..."
  sleep 10
done

if ! docker exec "$KOHA_CONTAINER" test -f /ktd_ready 2>/dev/null; then
  echo "koha-oauth: ktd never signaled ready, aborting" >&2
  exit 1
fi

KEYS=""
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  KEYS=$(docker exec -e USER_ID=koha "$KOHA_CONTAINER" perl \
    -MC4::Context -MKoha::Patrons -MKoha::ApiKey -MKoha::ApiKeys -Mt::lib::TestBuilder -e '
my $userid = $ENV{USER_ID};
my $patron = Koha::Patrons->search({ userid => $userid })->next;
unless ($patron) {
    my $b = t::lib::TestBuilder->new;
    $patron = $b->build_object({ class => "Koha::Patrons", value => { flags => 1, userid => $userid } });
}
C4::Context->set_preference("RESTOAuth2ClientCredentials", 1);
my $k = Koha::ApiKey->new({ patron_id => $patron->id, description => "aspen" })->store;
print "client_id: ", $k->{_result}->{_column_data}->{client_id}, "\n";
print "secret: ", $k->{_plain_text_secret}, "\n";
' 2>&1) || true
  if [ -n "$(echo "$KEYS" | sed -n 's/^client_id: //p')" ]; then
    break
  fi
  echo "koha-oauth: koha not ready, retrying in 10s..."
  KEYS=""
  sleep 10
done

CLIENT_ID=$(echo "$KEYS" | sed -n 's/^client_id: //p')
SECRET=$(echo "$KEYS" | sed -n 's/^secret: //p')

if [ -z "$CLIENT_ID" ] || [ -z "$SECRET" ]; then
  echo "koha-oauth: timed out after 5 minutes" >&2
  echo "$KEYS" >&2
  exit 1
fi

docker exec "$DB_CONTAINER" mariadb -uroot -paspen aspen -e \
  "UPDATE account_profiles SET oAuthClientId='$CLIENT_ID', oAuthClientSecret='$SECRET' WHERE id=2;"

echo "koha-oauth: keys configured"
