# ILS Integration

The dev box can attach Aspen to an ILS. The `--ils` flag on `adb up` controls
which one and how it's configured:

```shell
adb up                        # default: --ils koha
adb up --ils none             # no ILS at all
adb up --ils /path/to/my.yml  # custom ILS config file
```

When an ILS config is active, the CLI generates SQL from it (account profile,
indexing profile and any extras) into `.cache/ils-setup.sql`, which is applied
when the database container is first initialised.

**Note:** the ILS SQL runs when the database container initialises a fresh
data directory. The dev box database is not persisted across `adb down`, so
switching ILS configs takes effect after `adb down && adb up`, not on a
restart of a running stack.

## Koha (default)

`adb up` integrates with a running
[koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)
stack by joining its external `kohanet` network and pointing Aspen's account
profile at the Koha container.

**⚠️ Important:** koha-testing-docker must be up first, or the external
network won't exist and `adb up` will fail.

If you run multiple/proxied koha-testing-docker stacks, pick which one to
connect to:

```shell
adb up -k my-koha-stack       # default: kohadev
```

### OAuth

On first boot a helper container (`koha-oauth-init`) provisions OAuth API
credentials in Koha and writes them into Aspen's account profile
automatically. If you ever need to set credentials by hand — for example
against a different driver — use:

```shell
adb oauth <client_id> <client_secret> [-d Driver] [-p]
```

## Evergreen

An Evergreen stack is available as a compose overlay,
`docker-compose.evergreen.yml`. It is not currently wired into an `--ils`
preset; start it manually alongside the base compose file:

```shell
cd $ASPEN_DOCKER
docker compose -f docker-compose.yml -f docker-compose.evergreen.yml up -d
```

The overlay runs an Evergreen ILS container on a shared `evergreen-net`
network. It seeds Aspen's Evergreen account and indexing profiles via
`database_start_scripts/evergreen/` and mounts `export_utils/` into the main
container for export experiments. Pull its image with `adb pull -e`.

## Custom ILS configs

`--ils` accepts a path to a YAML file (anything containing a path separator or
ending in `.yml`/`.yaml`), so you can keep configs for your own ILS setups
outside this repository:

```shell
adb up --ils ~/configs/my-koha.yml
```

Preset names resolve to `ils/<name>.yml` in this repository. `koha` is the
shipped preset; names starting with `_` are reserved for shared base configs
and cannot be used directly.

A config file looks like this (trimmed from `ils/koha.yml`):

```yaml
base: _base.yml

driver: Koha

account_profile:
  name: ils
  driver: Koha
  loginConfiguration: barcode_pin
  authenticationMethod: ils
  vendorOpacUrl: http://${KOHA_STACK}-koha-1:8080
  databaseHost: ${KOHA_STACK}-db-1
  databaseUser: koha_kohadev
  databasePassword: password

indexing_profile:
  indexingClass: Koha
  catalogDriver: Koha

extras_sql: ils/extras/koha.sql
```

- `base` — another config to inherit from; `ils/_base.yml` holds the shared
  MARC indexing profile defaults. Child values override the parent.
  `indexing_profile` maps are merged key by key.
- `account_profile` / `indexing_profile` — column/value pairs inserted into
  Aspen's `account_profiles` and `indexing_profiles` tables.
  `${VARIABLES}` are expanded from the environment.
- `driver` — enables the matching Aspen module in the database.
- `extras_sql` — an optional SQL file, resolved relative to this repository's
  root (`$ASPEN_DOCKER`) even for external configs, run after the profiles for
  driver-specific rows such as translation maps.
