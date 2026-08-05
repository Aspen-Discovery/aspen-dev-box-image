# Getting Started

## Prerequisites

- Docker and Docker Compose v2 (Docker Desktop on macOS/Windows)
- For the default Koha integration: a running
  [koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker) stack

## Clone the repositories

Keep both clones in one directory. The instructions use `~/git`, change it
to wherever you keep your projects:

```shell
mkdir -p ~/git
export PROJECTS_DIR=~/git
```

* Clone the `aspen-dev-box` project:

```shell
cd $PROJECTS_DIR
git clone https://github.com/Aspen-Discovery/aspen-dev-box-image.git aspen-dev-box
```

* Clone the `aspen-discovery` project (skip and adjust the paths if you already
  have it). Forking the repository and cloning your fork is recommended:

```shell
cd $PROJECTS_DIR
git clone https://github.com/Aspen-Discovery/aspen-discovery.git aspen-discovery
```

## Environment variables

Set some **mandatory** environment variables in your .bashrc (or .zshrc):

```shell
echo "export PROJECTS_DIR=$PROJECTS_DIR" >> ~/.bashrc
echo 'export ASPEN_CLONE=$PROJECTS_DIR/aspen-discovery' >> ~/.bashrc
echo 'export ASPEN_DOCKER=$PROJECTS_DIR/aspen-dev-box'  >> ~/.bashrc
echo 'export UID=$(id -u)' >> ~/.bashrc
echo 'export GID=$(id -g)' >> ~/.bashrc
[ "$(uname)" == "Darwin" ] && echo 'export PATH=$PATH:$ASPEN_DOCKER/bin/darwin' >> ~/.bashrc
[ "$(uname)" == "Linux" ] && echo 'export PATH=$PATH:$ASPEN_DOCKER/bin/linux' >> ~/.bashrc
```

The `UID` and `GID` exports are required so the container can match its
internal users to your host user, avoiding file permission issues on
bind-mounted source code.

The `PATH` line puts the `adb` CLI on your path. Pre-built binaries for macOS,
Linux and Windows ship in `bin/`; the CLI source lives at
[aspen-dev-box-cli](https://github.com/aspen-discovery/aspen-dev-box-cli).

**Note:** you will need to log out and log back in (or start a new terminal
window) for this to take effect.

If you are on **WSL**, also add:

```shell
export WSL_IP=$(ip addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
```

This is used by the [debugging setup](debugging.md) to reach your IDE from
inside the container.

## Site configuration

Copy the example environment file and adjust to taste:

```shell
cd $ASPEN_DOCKER
cp .env.example .env
```

Review `.env` and change any values that differ from your local setup (site
name, timezone, passwords, etc.). See
[Services & Configuration](services-and-configuration.md) for what each value
does.

## Koha integration (default)

`adb up` defaults to `--ils koha`, which joins the dev box to a running
[koha-testing-docker](https://gitlab.com/koha-community/koha-testing-docker)
stack over its `kohanet` network and provisions Aspen's account and indexing
profiles for it.

**⚠️ Important:** if koha-testing-docker is not running, `adb up` will fail
because the external `kohanet` network does not exist. Either start
koha-testing-docker first, or skip ILS integration entirely:

```shell
adb up --ils none
```

See [ILS Integration](ils-integration.md) for proxied Koha stacks, Evergreen,
and custom ILS configurations.

## First boot

```shell
adb up -d
```

The first boot takes a few minutes because it has to download the docker
images. The container entrypoint then installs composer
dependencies, creates the site configuration, initialises the database, runs
any pending database updates and starts cron, PHP-FPM and Apache. Watch
progress with:

```shell
adb logs -f
```

Once you see the `Aspen dev box ready` banner:

- [localhost:8083](http://localhost:8083) — Aspen Discovery
  (`aspen_admin` / `password`)
- [localhost:8084](http://localhost:8084) — Solr dashboard

Direct database access is available with `adb db` (`root` / `aspen`), or run
`adb up -b` to add a phpMyAdmin container on localhost:8085.

## Day-to-day

```shell
adb up -d          # start (koha-testing-docker must be up)
adb logs -f        # follow the site logs
adb shell          # shell inside the aspen container
adb down           # stop everything
adb pull           # update the published images
```

The full command set is in the [CLI Reference](cli-reference.md).

## Troubleshooting

1. **`kohanet` network not found**: start koha-testing-docker, or use
   `adb up --ils none`.
2. **Port conflicts**: ports 8083 and 8084 (and 8085 with `--dbgui`) must be
   free; override the Aspen port with `ASPEN_PORT` in `.env`.
3. **Missing environment variables**: `adb` refuses to run without
   `ASPEN_DOCKER` and `ASPEN_CLONE`.
4. **File permission errors on the clone**: check the `UID`/`GID` exports are
   present in your shell before starting the stack.
5. **Debugger not connecting on WSL**: verify `WSL_IP` is exported and your
   shell was restarted.
