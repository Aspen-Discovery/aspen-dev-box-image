# Aspen Dev Environment

A Docker-based development environment for [Aspen Discovery](https://github.com/Aspen-Discovery/aspen-discovery),
driven by the `adb` CLI. It runs Aspen, MariaDB and Solr in containers with your
local Aspen clone bind-mounted in. It integrates with
[koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker) as
the default ILS.

## Requirements

- Docker ([download](https://www.docker.com/get-started/))
- Docker Compose v2 ([install instructions](https://docs.docker.com/compose/install/linux/#install-using-the-repository))
- A local clone of aspen-discovery

Note: **Windows** and **macOS** users use [Docker Desktop](https://www.docker.com/get-started/) which already ships Docker Compose v2.

## Quick start

You need to do the one-time setup first: clone both repositories, set the
environment variables (`ASPEN_DOCKER`, `ASPEN_CLONE`, `UID`, `GID`), put the
`adb` binary on your PATH and copy `.env.example` to `.env`.
[Getting Started](docs/getting-started.md) covers all of this. Once that's
done, starting the dev box is:

```shell
adb up -d
```

- [localhost:8083](http://localhost:8083) — the Aspen Discovery interface
- [localhost:8084](http://localhost:8084) — the Solr dashboard

**Note:** by default `adb up` connects to a running
[koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)
stack. Start that first, or run `adb up --ils none` for a standalone Aspen.

**Logins:**

* Discovery:
```
Username: aspen_admin
Password: password
```
* Database:
```
Username: root
Password: aspen
Database: aspen
```

## Documentation

- [Getting Started](docs/getting-started.md) — prerequisites, environment variables, first boot
- [CLI Reference](docs/cli-reference.md) — every `adb` command and flag
- [Debugging](docs/debugging.md) — PHP step debugging with Xdebug, Java debugging
- [ILS Integration](docs/ils-integration.md) — Koha, Evergreen and custom ILS configs
- [Plugins](docs/plugins.md) — developing Aspen plugins against the dev box
- [Services & Configuration](docs/services-and-configuration.md) — containers, compose overlays, `.env` reference
