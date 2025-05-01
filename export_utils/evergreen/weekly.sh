#!/bin/bash

set -u

# Weekly (full) extract / uploads for Aspen indexing

### BEGIN EDITS

# Pg connection info, can be overridden by setting PG* env vars
export PGPASSWORD=databasepassword
def_pguser="evergreen"
def_pghost="localhost"
def_db="evergreen"

# Where is marc_export(_custom)? Can be overridded by EG_BIN_DIR env var
def_eg_bin="/openils/bin"

# How many records to export at once
split_lines="2500"

### END EDITS

# Shouldn't need to edit anything below here

# Make sure we're in a known place
cd "$(dirname $0)"
script_dir="$(pwd)"

# Temp dir for files
scratch="${script_dir}/scratch"
mkdir -p "$scratch"

# Where is the opensrf_core.xml config?
osrf_xml="/openils/conf/opensrf_core.xml"

sql="${script_dir}/sql"

psql_flags="-A -q -t -X"
pguser="${PGUSER:-$def_pguser}"
pghost="${PGHOST:-$def_pghost}"
pgdb="${PGDATABASE:-$def_db}"

eg_bin="${EG_BIN_DIR:-$def_eg_bin}"

exporter_bin="marc_export"
if [ -x "$eg_bin/marc_export_custom" ]; then
  exporter_bin="marc_export_custom"
fi

marc21_ids="${scratch}/marc21.ids"
marcxml_ids="${scratch}/marcxml.ids"
marc21="${scratch}/marc21.mrc"
marcxml="${scratch}/large_bibs.xml"
all="${scratch}/all_bibs.mrc"

# SQL files need to specify file names only, like so:
# \o file.ids
# SELECT id FROM ...

date

cd "$scratch"

psql $psql_flags -U "$pguser" -h "$pghost" -f "${sql}/weekly.sql" "$pgdb"

date

# Split bib with copies id lists into more managable chunks
echo "Extracting marc21 for bibs with fewer copies"
date
split -l "$split_lines" "$marc21_ids" xpt
for x in xpt* ; do
  if [ "$x" = 'xpt*' ]; then # when no files exist that match the glob you just get the glob.
    continue
  fi
  echo "$x"
  cat $x | "${eg_bin}/$exporter_bin" --encoding UTF-8 --check-leader --items --exclude-hidden --852b circ_lib --config "$osrf_xml" > "${marc21}.$x"
done

# Throw all of the MARC21 bibs into the all_bibs file
cat ${marc21}.xpt* > "$all"
rm "$marc21_ids" ${marc21}.xpt* xpt*

# Extract bibs with so many copies that they can't be held in a binary MARC record
echo "Extracting marcxml for bibs with many copies"
date

# Can't really split these without more hassle joining them together.
cat "$marcxml_ids" | "${eg_bin}/$exporter_bin" -f XML --encoding UTF-8 --check-leader --items --exclude-hidden --852b circ_lib --config "$osrf_xml" > "$marcxml"

rm "$marcxml_ids"

echo "Done"
date

# Bye!
echo exported to: "$all" "$marcxml"

exit 0
