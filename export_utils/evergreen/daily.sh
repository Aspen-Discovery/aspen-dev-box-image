#!/bin/bash

# Daily extract / uploads for Aspen indexing

# Aspen upload user / host
upl_user="noble_test"
upl_host="noble-test.libdiscovery.org"
sftp_port="2202"

# Pg connection info, can be overridden by PG* env vars
def_pguser="evergreen"
def_pghost="localhost"
def_db="evergreen"


# Shouldn't need to edit anything below here

# Make sure we're in a known place
cd "$(dirname $0)"
script_dir="$(pwd)"

# Temp dir for files
scratch="${script_dir}/scratch"
mkdir -p "$scratch"

# Where does the sql live
sql="${script_dir}/sql"

psql_flags="-A -q -t -X"
pguser="${PGUSER:-$def_pguser}"
pghost="${PGHOST:-$def_pghost}"
pgdb="${PGDATABASE:-$def_db}"

# daily.sql creates parts and item create date extracts (the active filename is an aspen requirement, even though internally they're treated as create dates.)
parts="${scratch}/parts.csv"
active="${scratch}/barcode_active_dates.csv"
holds="${scratch}/holds.csv"

# SQL files need to specify file names only, like so:
# \o file.ext
# SELECT id FROM ...

date

cd "${scratch}"

psql $psql_flags -U "$pguser" -h "$pghost" -f "${sql}/daily.sql" "$pgdb"

echo "Uploading files"

sftp -C -q -b -P "$sftp_port" - "$upl_user@$upl_host" <<EOT
cd supplemental
put "$parts"
put "$active"
put "$holds"
EOT

echo "Done"

date

# These things are point-in-time snapshots; there's no need to keep them after upload
rm "$parts" "$active" "$holds"

