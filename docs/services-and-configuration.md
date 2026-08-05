# Services & Configuration

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `aspen-dev-box` | `aspendiscovery/aspen:latest` | `8083:80` (set with `ASPEN_PORT`) | Aspen itself — Apache, PHP-FPM, cron, background jobs |
| `aspen-db` | `mariadb:10.11.5` | — | The Aspen database, initialised from `$ASPEN_CLONE/install/aspen.sql` |
| `solr` | `aspendiscovery/solr:latest` | `8084:8084` | Solr with Aspen's cores precreated |
| `phpmyadmin` | `phpmyadmin` | `8085:80` | Database GUI, only with `adb up -b` |

Your aspen-discovery clone is bind-mounted at `/usr/local/aspen-discovery` in
the main container, so code changes on the host apply immediately.

**Note:** the database has no persistent volume — `adb down` discards it and
the next `adb up` re-initialises from `aspen.sql` plus any ILS setup SQL.

## Compose overlays

`docker-compose.yml` defines the core stack; overlays add features. `adb`
selects them by flag:

| File | Added by | Purpose |
|------|----------|---------|
| `docker-compose.debug.yml` | `adb up -g` | Xdebug config for PHP step debugging |
| `docker-compose.dbgui.yml` | `adb up -b` | phpMyAdmin |
| `docker-compose.ils.yml` | any `--ils` config | Applies the generated ILS setup SQL |
| `docker-compose.koha.yml` | `--ils koha` | Joins the koha-testing-docker network, OAuth provisioning |
| `docker-compose.plugins.yml` | `--plugins` | Plugin dir mount |
| `docker-compose.evergreen.yml` | manual `-f` | Evergreen ILS stack |
| `docker-compose.debug.java.yml` | manual `-f` | JDWP port for Java debugging |

## `.env` reference

Copy `.env.example` to `.env` and adjust. Values are read by docker compose
and passed into the containers.

| Variable | Default | Purpose |
|----------|---------|---------|
| `SITE_NAME` | `dev.localhost` | Site identifier; names the config, data and log directories |
| `URL` | `http://localhost:80` | Site base URL |
| `TITLE` | `Aspen Discovery Dev` | Site display name |
| `LIBRARY` | `Test Library` | Main library name |
| `TIMEZONE` | `Europe/London` | Site timezone |
| `ASPEN_ADMIN_PASSWORD` | `password` | `aspen_admin` login password |
| `SUPPORTING_COMPANY` | `DEV MACHINE` | Displayed supporting company |
| `DATABASE_HOST` / `DATABASE_PORT` | `aspen-db` / `3306` | Database connection (must match the `aspen-db` service) |
| `DATABASE_NAME` / `DATABASE_USER` / `DATABASE_PASSWORD` | `aspen` / `aspensuper` / `aspensuper` | Aspen's database and credentials |
| `DATABASE_ROOT_PASSWORD` | `aspen` | MariaDB root password |
| `SOLR_HOST` / `SOLR_PORT` | `solr` / `8084` | Solr connection |
| `PHP_FPM_HOST` / `PHP_FPM_PORT` | `127.0.0.1` / `9000` | Apache → PHP-FPM proxying inside the container |
| `ASPEN_PLUGINS` | `$ASPEN_DOCKER/plugins` | Host plugins directory ([Plugins](plugins.md)) |

Shell-level variables (not in `.env`) are covered in
[Getting Started](getting-started.md#environment-variables): `ASPEN_DOCKER`,
`ASPEN_CLONE`, `UID`, `GID` and, for WSL debugging, `WSL_IP`. `ASPEN_PORT` can
be exported to move Aspen off port 8083.

## What the entrypoint does

The main container's entrypoint is `dockerrun.sh` from this repository. On
every start it:

1. installs composer and the web dependencies
2. detects the image's PHP version (nothing here is pinned to one)
3. remaps the container users to your host `UID`/`GID` so bind-mounted files
   stay yours
4. creates the site configuration under
   `$ASPEN_CLONE/sites/<SITE_NAME>` if missing and syncs `.env` values into it
5. initialises the database and runs any pending database updates
6. wires in the debug config when present
   ([Debugging](debugging.md#how-it-works))
7. starts cron, PHP-FPM and Apache, then prints the
   `Aspen dev box ready` banner

## In-container aliases

`adb shell` loads a bashrc with shortcuts:

| Alias | Does |
|-------|------|
| `aspen_logs` | Tail all site logs |
| `aspen_dir` | `cd /usr/local/aspen-discovery` |
| `aspen_code` | `cd /usr/local/aspen-discovery/code` |
| `aspen_site` | `cd` into the site config directory |
| `aspen_koha_import` | Run the Koha export JAR |
| `aspen_reindex` | Run the reindexer JAR |

The same jobs (and more) are available from the host via
[`adb run`](cli-reference.md#adb-run-job-extra-args).
