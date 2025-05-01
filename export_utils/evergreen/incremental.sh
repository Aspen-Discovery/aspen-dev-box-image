#!/bin/bash

# Incremental id extract / uploads for Aspen indexing

# Aspen upload user / host
upl_user="noble_test"
upl_host="noble_test.libdiscovery.org"
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

filedate="$(date +%Y-%m-%d-%H%M)"
inc="${scratch}/incremental_changes.ids"
all="${scratch}/all_bib.ids"

date

# SQL files need to specify file names only, like so:
# \o file.ext
# SELECT id FROM ...

cd "${scratch}"

psql $psql_flags -U "$pguser" -h "$pghost" -f "${sql}/incremental.sql" "$pgdb"

echo "Uploading files"
date

# Multiple _changes files will be gathered and acted on together, but only the latest all_bib.ids
sftp -C -q -b -P "$sftp_port" - "$upl_user@$upl_host" <<EOT
cd marc_delta
put "$inc" "incremental_changes.$$.ids"
put "$all"
EOT

echo "Done"
date

# These things are point-in-time snapshots; there's no need to keep them after a successful upload
rm "$inc" "$all"

date

