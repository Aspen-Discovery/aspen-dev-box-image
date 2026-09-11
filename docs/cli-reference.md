# CLI Reference

`adb` is the Aspen Dev Box CLI. It wraps docker compose with the right overlay
files and provides shortcuts for common development tasks. Source:
[aspen-dev-box-cli](https://github.com/aspen-discovery/aspen-dev-box-cli);
pre-built binaries ship in this repository under `bin/`.

Every command supports `--help`.

## Requirements

The CLI needs two environment variables (see
[Getting Started](getting-started.md)):

- `ASPEN_DOCKER` — path to this repository
- `ASPEN_CLONE` — path to your aspen-discovery clone

The docker compose project ("stack") name is resolved in this order:
`--stack` flag, `ASPEN_STACK`, `COMPOSE_PROJECT_NAME`, then the basename of
`$ASPEN_DOCKER`. Container names follow `<stack>-<service>-1`.

`-w, --worktree <name>` targets a [git worktree](https://git-scm.com/docs/git-worktree)
of `$ASPEN_CLONE` instead of the main checkout, matched by directory or
branch name from `git worktree list`. Its checkout becomes `ASPEN_CLONE` and
its (sanitised) directory name becomes the stack, so every command (`up`,
`logs`, `shell`, ...) operates on that instance:

```shell
git -C $ASPEN_CLONE worktree add ../aspen-my-feature my-feature
adb -w aspen-my-feature up -d       # or -w my-feature (branch name)
adb -w aspen-my-feature logs -f
adb -w aspen-my-feature down
```

## Stack lifecycle

### `adb up`

Bring up the Docker Compose project, routed through the aspen proxy
([Aspen Proxy](proxy.md)) — started automatically if it isn't running. The
default instance is served on [localhost:8083](http://localhost:8083) as
always; worktrees and named stacks get `http://<stack>.localhost:8083`.
`--no-proxy` binds host ports directly instead.

| Flag | Description |
|------|-------------|
| `-d, --detached` | Run in detached mode |
| `--wait` | Detach and block until every service is healthy, i.e. Aspen answers on port 80 |
| `-g, --debugging` | Include the Xdebug overlay ([Debugging](debugging.md)) |
| `-j, --java-debug` | Expose JDWP port 5005 for `adb debug` ([Debugging](debugging.md#java-debugging-jdwp)) |
| `-b, --dbgui` | Include phpMyAdmin on port 8085 (served on the instance hostname when proxied) |
| `-p, --pull` | Pull registry images before starting |
| `-i, --ils` | ILS preset name, path to a YAML config, or `none` (default: `koha`) |
| `-k, --koha-stack` | koha-testing-docker stack to connect to (default: `kohadev`) |
| `--plugins` | Mount a plugins dir and enable Aspen plugin loading ([Plugins](plugins.md)) |
| `--plugins-path` | Host path of the plugins dir (default: `$ASPEN_PLUGINS` or `$ASPEN_DOCKER/plugins`) |
| `--no-proxy` | Bind host ports directly instead of routing through the proxy |
| `--host` | Hostname to serve when proxied (default: `localhost` for the default instance, else `<stack>.localhost`) |
| `--no-cron` | Boot with cron stopped so scheduled jobs stay quiet (`adb cron start` turns it on) |

```shell
adb up -d                     # detached, default Koha integration
adb up --wait                 # detached, returns once Aspen is serving pages
adb up -d -g                  # with PHP debugging
adb up -d --no-cron           # no scheduled jobs while you debug
adb up --ils none             # standalone Aspen, no ILS
adb up --ils evergreen        # Evergreen instead of Koha
adb up -i /path/to/custom.yml # custom ILS config
adb up -k my-koha-stack       # proxied koha-testing-docker stack
adb up -d --no-proxy          # old-style host ports, no proxy involved
```

### `adb down`

Stop and remove the project’s containers, its database and Solr volumes and
the generated ILS SQL, so the next `adb up` starts from a fresh database.
`--keep-data` keeps the volumes and ILS SQL: the next `adb up` of the same
stack reuses the database and index instead of re-initialising. The aspen
proxy is stopped along with the last proxied stack.

| Flag | Description |
|------|-------------|
| `--keep-data` | Keep the database and Solr volumes for the next `adb up` |
| `--all` | Bring down every aspen stack (any worktree or stack name) and the proxy |

```shell
adb down                      # fresh database next time
adb down --keep-data          # containers go, data stays
```

### `adb stop`, `adb start`, `adb restart`

Stop, start or restart the stack's containers in place. Unlike `adb down`
the containers, the database and the generated ILS SQL are kept, so `adb
start` brings everything back as it was and `adb restart` re-runs the aspen
entrypoint against the existing database (handy after editing
`dockerrun.sh` or the site config). Pass service names to act on a subset.

```shell
adb stop                      # pause the stack, keep the database
adb start
adb restart aspen-dev-box     # re-run the entrypoint only
```

### `adb ls`

List every aspen stack docker knows about (the default instance, worktrees
and `--stack` names) with the state of its aspen, database and Solr
containers, its URL, the ILS it is wired to (including whether the Koha OAuth
setup succeeded) and the clone it serves. The stack `adb` currently targets
is marked with `*`. `adb list` and `adb ps` are aliases.

### `adb doctor`

Check the machine before the first `adb up`: `ASPEN_DOCKER` and `ASPEN_CLONE`
point at the right checkouts, `.env` exists, the host `UID`/`GID` mapping,
the docker daemon and compose v2, the koha-testing-docker network the default
`--ils koha` needs, and the host ports the proxy binds. Exits non-zero when
something needs fixing. `adb doctor` is the one command that runs without
`ASPEN_DOCKER`/`ASPEN_CLONE` set.

| Flag | Description |
|------|-------------|
| `-k, --koha-stack` | koha-testing-docker stack whose network to look for (default: `kohadev`) |

### `adb proxy`

Manually start or stop the aspen traefik proxy that routes every proxied
aspen stack by hostname on the external `aspen-proxy` network
([Aspen Proxy](proxy.md)) — usually unnecessary, since `adb up`/`adb down`
manage it. It is fully independent of koha-testing-docker's proxy. The
dashboard is served on
[localhost:8090/dashboard/](http://localhost:8090/dashboard/).

```shell
adb proxy up
adb proxy down
```

### `adb pull`

Pull every image the dev box uses: everything referenced by the compose files
(the stack, all overlays, the proxy) plus the JDK and less images behind
`adb jarbuild` and `adb compilecss`. The Evergreen image is large and only
pulled on request.

| Flag | Description |
|------|-------------|
| `-e, --evergreen` | Also pull the Evergreen ILS image |

### `adb version`

Print the build version (`git describe` of the CLI source at build time), Go
version and platform. `adb --version` prints the short form.

## Working with the running stack

### `adb shell`

Open a bash shell inside the main container, starting in
`/usr/local/aspen-discovery`. The container users are mapped to your host
user, so any files you create are still owned by you. Passwordless sudo is
available if you need root. Some helper aliases are preloaded, see
[Services & Configuration](services-and-configuration.md#in-container-aliases).

### `adb logs`

View the site logs from the main container
(`/var/log/aspen-discovery/<SITE_NAME>/`), or with `--container` the
container's own output: the entrypoint progress and the
`Aspen dev box ready` banner. `--service` shows the output of any other
container of the stack.

| Flag | Description |
|------|-------------|
| `-f, --follow` | Follow logs in real time |
| `-i, --include-indexing` | Include the indexing logs |
| `-c, --container` | Show the aspen container's stdout (entrypoint, boot banner) instead of the site logs |
| `-s, --service` | Show another service's container output: `aspen-db`, `solr`, `koha-oauth-init`, `phpmyadmin` |

```shell
adb logs -f                   # site logs
adb logs -c -f                # watch a boot
adb logs --service solr       # why is Solr unhealthy
adb logs --service koha-oauth-init
```

### `adb db`

Open an interactive MariaDB shell connected to the Aspen database, or manage
snapshots of it. Snapshots are gzipped `mariadb-dump` files under
`$ASPEN_DOCKER/.cache/snapshots/<stack>-<name>.sql.gz`, so they survive
`adb down` and can be restored into a fresh stack.

| Subcommand | Description |
|------------|-------------|
| `dump [name]` | Dump the database to a snapshot (default name `latest`) |
| `restore [name]` | Replace the database contents with a snapshot; run `adb updatedb` afterwards if the schema has moved on |
| `snapshots` | List this stack's snapshots |

```shell
adb db                        # interactive shell
adb db dump before-migration
adb db restore before-migration
adb db snapshots
```

### `adb xdebug on|off|status`

Enable or disable the Xdebug extension for web requests in the running
container and reload PHP-FPM, without restarting the stack. `on` installs the
settings from `xdebug.ini` in this repository (mode, client host,
`start_with_request`); `status` reports what the running PHP-FPM has loaded.
See [Debugging](debugging.md#php-step-debugging-xdebug).

### `adb cron start|stop|status`

Control the cron daemon that runs Aspen's scheduled jobs inside the
container. Stop it while stepping through a job so the scheduler does not
launch a second copy; `adb up --no-cron` boots with it already stopped.

### `adb updatedb`

Run any pending Aspen database updates via the SystemAPI and print the results,
including any failed SQL.

### `adb tests [phpunit args...]`

Run the Aspen phpunit suite in a separate container against its own database
(`aspen_unit_tests`). The dev database, site config and running containers
are not touched, but the stack must already be up (`adb up -d`). Extra
arguments are passed through to phpunit.

The suite drops and reimports the test database at the start of every run
(the base `install/aspen.sql` schema plus the test data in
`tests/unit_tests.sql`), so every run starts from the same state. Pending
database updates are not applied unless you pass `--updatedb`, which the
runner consumes (it is not forwarded to phpunit) and which makes the bootstrap
apply them after the fresh import.

```shell
adb tests
adb tests --filter DateUtilsTests
adb tests --updatedb --filter UserAPITests
```

### `adb run <job> [extra args...]`

Run an Aspen background job inside the main container. Jobs are invoked with
the site name. Any extra arguments are passed through.

Jar jobs are discovered from your aspen clone: any module under `code/` with
a built `<module>.jar` can be run using its module name (`reindexer`,
`koha_export`, `oai_indexer`, ...). Two PHP jobs are always available: `cron`
(background process check) and `sitemaps` (sitemap creation).

```shell
adb run list                  # list the jobs available in your clone
adb run reindexer
adb run koha_export
```

The job's exit code becomes `adb`'s exit code, so `adb run` works in scripts.

### `adb debug <module> [extra args...]`

Compile a Java module from source inside the container and run it under the
JDWP agent, suspended until your IDE attaches on `localhost:5005`. Needs the
stack up with `adb up -j`. Any module under `code/` with a
`META-INF/MANIFEST.MF` is debuggable; `adb debug list` shows them. See
[Debugging](debugging.md#java-debugging-jdwp).

```shell
adb debug list
adb debug reindexer
```

### `adb seed <command> [args...]`

Generate test data using the bundled seeder (mounted at `/seeder` in the
container).

```shell
adb seed list                        # list seedable tables and custom types
adb seed build library 500          # build 500 libraries
adb seed build user 10 password=foo # field overrides as key=value
```

`build` works against any database table generically; custom types (currently
`library`) generate more realistic identities.

### `adb oauth <client_id> <client_secret>`

Update the OAuth client credentials on Aspen's account profiles, for ILS
logins.

| Flag | Description |
|------|-------------|
| `-d, --driver` | Account profile driver to update (default: `Koha`) |
| `-p, --print` | Print the matching rows after updating |

With the default Koha integration this usually is not needed — credentials are
provisioned automatically ([ILS Integration](ils-integration.md#oauth)).

## Build tooling

### `adb jarbuild [module]`

Build Aspen's Java modules in a containerised JDK 17 (`eclipse-temurin:17`,
the same major version as the aspen image). Pass a module name to build that
JAR, or run without arguments for an interactive fuzzy-search of the available
modules; shared java libraries are compiled in automatically when the module
uses them.

| Flag | Description |
|------|-------------|
| `-a, --all` | Build every JAR |

```shell
adb jarbuild reindexer
adb jarbuild --all
```

### `adb compilecss`

Compile `main.less` to `main.css` for the responsive theme, in a containerised
less compiler.

| Flag | Description |
|------|-------------|
| `-r, --rtl` | Compile the right-to-left stylesheet instead |

### `adb mergejs`

Merge and minify the responsive theme's JavaScript via Aspen's
`merge_javascript.php`, inside the main container.

## Shell completion

`adb completion bash|zsh|fish|powershell` generates a completion script; see
`adb completion --help` for install instructions per shell.
