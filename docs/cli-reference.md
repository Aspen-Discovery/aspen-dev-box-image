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
`--stack` flag, `COMPOSE_PROJECT_NAME`, then the basename of
`$ASPEN_DOCKER`. Container names follow `<stack>-<service>-1`.

## Stack lifecycle

### `adb up`

Bring up the Docker Compose project.

| Flag | Description |
|------|-------------|
| `-d, --detached` | Run in detached mode |
| `-g, --debugging` | Include the Xdebug overlay ([Debugging](debugging.md)) |
| `-b, --dbgui` | Include phpMyAdmin on localhost:8085 |
| `-p, --pull` | Pull registry images before starting |
| `-i, --ils` | ILS preset name, path to a YAML config, or `none` (default: `koha`) |
| `-k, --koha-stack` | koha-testing-docker stack to connect to (default: `kohadev`) |
| `--plugins` | Mount a plugins dir and enable Aspen plugin loading ([Plugins](plugins.md)) |
| `--plugins-path` | Host path of the plugins dir (default: `$ASPEN_PLUGINS` or `$ASPEN_DOCKER/plugins`) |

```shell
adb up -d                     # detached, default Koha integration
adb up -d -g                  # with PHP debugging
adb up --ils none             # standalone Aspen, no ILS
adb up --ils evergreen        # Evergreen instead of Koha
adb up -i /path/to/custom.yml # custom ILS config
adb up -k my-koha-stack       # proxied koha-testing-docker stack
```

### `adb down`

Stop and remove the project's containers, including orphans.

### `adb pull`

Pull the registry images for the selected compose files.

| Flag | Description |
|------|-------------|
| `-g, --debugging` | Include the debugging compose file |
| `-b, --dbgui` | Include the phpMyAdmin image |
| `-e, --evergreen` | Include the Evergreen image |

## Working with the running stack

### `adb shell`

Open a bash shell inside the main container, starting in
`/usr/local/aspen-discovery`. The container users are mapped to your host
user, so any files you create are still owned by you. Passwordless sudo is
available if you need root. Some helper aliases are preloaded, see
[Services & Configuration](services-and-configuration.md#in-container-aliases).

### `adb logs`

View the site logs from the main container
(`/var/log/aspen-discovery/<SITE_NAME>/`).

| Flag | Description |
|------|-------------|
| `-f, --follow` | Follow logs in real time |
| `-i, --include-indexing` | Include the indexing logs |

### `adb db`

Open an interactive MariaDB shell connected to the Aspen database.

### `adb updatedb`

Run any pending Aspen database updates via the SystemAPI and print the results,
including any failed SQL.

### `adb run <job> [extra args...]`

Run an Aspen background job inside the main container. Jobs are invoked with
the site name. Any extra arguments are passed through.

```shell
adb run list                  # list available jobs
adb run reindexer
adb run koha-export
```

Available jobs:

| Job | Runs |
|-----|------|
| `reindexer` | Grouped work reindexer |
| `oai-indexer` | OAI indexer |
| `web-indexer` | Website indexer |
| `events-indexer` | Events indexer |
| `series-indexer` | Series indexer |
| `course-reserves` | Course reserves indexer |
| `user-lists` | User list indexer |
| `sideload` | Sideload processing |
| `marc-merge` | MARC merge utility |
| `koha-export` | Koha export |
| `evergreen-export` | Evergreen export |
| `polaris-export` | Polaris export |
| `sierra-export` | Sierra export API |
| `carlx-export` | CarlX export |
| `symphony-export` | Symphony export |
| `evolve-export` | Evolve export |
| `hoopla-export` | Hoopla export |
| `overdrive-export` | OverDrive extract |
| `cloud-library-export` | Cloud Library export |
| `palace-project-export` | Palace Project export |
| `cron-jar` | Cron JAR |
| `cron` | PHP background process check |
| `sitemaps` | PHP sitemap creation |

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

### `adb jarbuild`

Build Aspen's Java modules in a containerised JDK. Without flags it offers an
interactive fuzzy-search of the available modules; shared java libraries are
compiled in automatically when the module uses them.

| Flag | Description |
|------|-------------|
| `-a, --all` | Build every JAR |

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
