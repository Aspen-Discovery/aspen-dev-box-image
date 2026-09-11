# Services & Configuration

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `aspen-dev-box` | `aspendiscovery/aspen:latest` (`ASPEN_IMAGE`) | `8083:80` (`ASPEN_PORT`) | Aspen itself — Apache, PHP-FPM, cron, background jobs. Reports healthy once it serves its homepage |
| `aspen-db` | `mariadb:10.11.5` | — | The Aspen database, initialised from `$ASPEN_CLONE/install/aspen.sql` |
| `solr` | official `solr:<major>` (`SOLR_IMAGE`) | `8084:8084` (`SOLR_HOST_PORT`) | Solr with Aspen's cores precreated from the checkout's configsets |
| `phpmyadmin` | `phpmyadmin` | `8085:80` (`DBGUI_PORT`) | Database GUI, only with `adb up -b` |

The ports column applies with `--no-proxy`; by default the stack is served
through the [proxy](proxy.md) and binds no host ports itself.

Your aspen-discovery clone is bind-mounted at `/usr/local/aspen-discovery` in
the main container, so code changes on the host apply immediately.

`adb` picks the Solr image from your checkout: it reads `luceneMatchVersion`
from `data_dir_setup/solr*/*/conf/solrconfig.xml` and uses the matching
official `solr:<major>` image, mounting that directory as the configsets.
`SOLR_IMAGE` and `SOLR_CONFIGSETS` override both.

**Note:** the database has no persistent volume — `adb down` discards it and
the next `adb up` re-initialises from `aspen.sql` plus any ILS setup SQL.
`adb stop`/`adb start`/`adb restart` keep it.

## Compose overlays

`compose/docker-compose.yml` defines the core stack; overlays add features. `adb`
selects them by flag:

| File | Added by | Purpose |
|------|----------|---------|
| `compose/docker-compose.debug.yml` | `adb up -g` | Xdebug config for PHP step debugging |
| `compose/docker-compose.dbgui.yml` | `adb up -b` | phpMyAdmin |
| `compose/docker-compose.ils.yml` | any `--ils` config | Applies the generated ILS setup SQL |
| `compose/docker-compose.koha.yml` | `--ils koha` | Joins the koha-testing-docker network, OAuth provisioning |
| `compose/docker-compose.plugins.yml` | `--plugins` | Plugin dir mount |
| `compose/docker-compose.evergreen.yml` | `--ils evergreen` | Evergreen ILS stack |
| `compose/docker-compose.debug.java.yml` | `adb up -j` | JDWP port for `adb debug` |
| `compose/docker-compose.tests.yml` | `adb tests` | Throwaway phpunit runner with its own database |
| `compose/docker-compose.proxied-instance.yml` | proxy running | Drops host ports, routes the stack by hostname ([Aspen Proxy](proxy.md)) |
| `compose/docker-compose.proxied-dbgui.yml` | proxy + `-b` | Routes phpMyAdmin by hostname too |

## `.env` reference

Copy `.env.example` to `.env` and adjust. `adb` loads the file itself and
docker compose passes the values into the containers; anything exported in
your shell takes precedence over the file.

| Variable | Default | Purpose |
|----------|---------|---------|
| `SITE_NAME` | `dev.localhost` | Site identifier; names the config, data and log directories (the proxy overlay sets it to the instance hostname) |
| `URL` | `http://localhost:8083` | Site base URL (the proxy overlay derives it from the instance hostname) |
| `TITLE` | `Aspen Discovery Dev` | Site display name |
| `LIBRARY` | `Test Library` | Main library name |
| `TIMEZONE` | `Europe/London` | Site timezone |
| `ASPEN_ADMIN_PASSWORD` | `password` | `aspen_admin` login password |
| `SUPPORTING_COMPANY` | `DEV MACHINE` | Displayed supporting company |
| `DATABASE_HOST` / `DATABASE_PORT` | `aspen-db` / `3306` | Database connection (must match the `aspen-db` service) |
| `DATABASE_NAME` / `DATABASE_USER` / `DATABASE_PASSWORD` | `aspen` / `aspensuper` / `aspensuper` | Aspen's database and credentials; also used by the `aspen-db` service, phpMyAdmin and the Koha OAuth setup |
| `DATABASE_ROOT_PASSWORD` | `aspen` | MariaDB root password |
| `SOLR_HOST` / `SOLR_PORT` | `solr` / `8084` | Solr connection |
| `ASPEN_IMAGE` | `aspendiscovery/aspen:latest` | Image for the aspen and unit-tests containers; pin a tag or point at a local build |
| `SOLR_IMAGE` / `SOLR_CONFIGSETS` | detected from the checkout | Solr image and configsets directory, see above |
| `ASPEN_PORT` / `SOLR_HOST_PORT` / `DBGUI_PORT` / `JAVA_DEBUG_PORT` | `8083` / `8084` / `8085` / `5005` | Host ports with `--no-proxy` (`JAVA_DEBUG_PORT` always binds, JDWP is not HTTP) |
| `PROXY_HTTP_PORT` / `PROXY_HTTPS_PORT` / `PROXY_SOLR_PORT` / `PROXY_DBGUI_PORT` / `PROXY_DASHBOARD_PORT` | `8083` / `8443` / `8084` / `8085` / `8090` | Host ports the proxy binds ([Aspen Proxy](proxy.md)) |
| `KOHA_STACK` | `kohadev` | koha-testing-docker stack to join; `adb up -k` sets it per run |
| `PHP_FPM_HOST` / `PHP_FPM_PORT` | `127.0.0.1` / `9000` | Apache → PHP-FPM proxying inside the container |
| `ASPEN_PLUGINS` | `$ASPEN_DOCKER/plugins` | Host plugins directory ([Plugins](plugins.md)) |

Shell-level variables (not in `.env`) are covered in
[Getting Started](getting-started.md#environment-variables): `ASPEN_DOCKER`,
`ASPEN_CLONE` and, for WSL debugging, `WSL_IP`. `UID`/`GID` are derived from
your user by `adb`; exporting them overrides that.

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

`adb logs -c` shows this output; the container reports healthy (and
`adb up --wait` returns) once Apache serves the homepage for `SITE_NAME`.

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
