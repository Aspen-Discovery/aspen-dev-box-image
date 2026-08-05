# Debugging

## PHP step debugging (Xdebug)

Start the stack with the debugging overlay:

```shell
adb up -d -g
```

### How it works

The overlay (`docker-compose.debug.yml`) mounts `xdebug.ini` and
`error_reporting.ini` from this repository into the container at
`/aspen-dev-conf/`. On startup the entrypoint detects the container's PHP
version and, when the Xdebug extension is present in the image, links the
config into that version's PHP-FPM configuration. Web requests then run with
`xdebug.mode=develop,debug` and `xdebug.start_with_request=yes`, connecting
out to your IDE at `host.docker.internal:9003`.

The Xdebug configuration applies to PHP-FPM (web requests) only, so cron and
CLI scripts don't open debugger connections on every run. See
[Debugging CLI scripts](#debugging-cli-scripts) for how to debug those on
demand.

**Note:** if the container logs show
`WARNING: xdebug extension not present in this image, step debugging disabled`,
the base image was built without the Xdebug extension and the overlay cannot
enable it. Pull or build an image that includes `php-xdebug`.

On **WSL**, export `WSL_IP` before starting the stack (see
[Getting Started](getting-started.md#environment-variables)) — it is used so
the container can reach your IDE across the WSL network boundary.

### IDE setup

Xdebug reports file paths as the container sees them
(`/usr/local/aspen-discovery/...`), so your IDE must translate them to your
clone. Two options:

**Option 1 — path mappings (recommended).** This repository ships an editor
config with the mapping already set up:

```shell
cp $ASPEN_DOCKER/vscodedebugconfig.json $ASPEN_CLONE/.vscode/launch.json
cp $ASPEN_DOCKER/vscodetasksconfig.json $ASPEN_CLONE/.vscode/tasks.json
```

Open your editor at the clone root, start the
**"Aspen container: Listen for Xdebug"** configuration and load a page.

- **VS Code**: needs the [PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug)
  extension.
- **Neovim (nvim-dap)**: needs the same adapter (`php-debug-adapter` via
  mason, or vscode-php-debug directly). nvim-dap reads `.vscode/launch.json`
  automatically when you start a session from the project root — pick
  "Aspen container: Listen for Xdebug" from the configuration list. The config
  uses `${workspaceFolder}`, which both editors expand.

**Option 2 — symlink.** Link your clone to the container path and open your
IDE from that location, so no mapping is needed:

```shell
sudo ln -s $ASPEN_CLONE /usr/local/aspen-discovery
```

### Debugging CLI scripts

The extension is loaded for CLI PHP but stays in `develop` mode. The
overlay's Xdebug settings (including the client host) apply to PHP-FPM only.
To step-debug a script inside the container, request debug mode and the client
host explicitly with your IDE listening:

```shell
XDEBUG_MODE=debug XDEBUG_CONFIG="client_host=host.docker.internal" \
  XDEBUG_TRIGGER=1 php somescript.php
```

### Troubleshooting

- **Breakpoints never hit but pages load fine**: almost always path mapping —
  verify your session uses the config with `pathMappings` and that your
  editor was opened at the clone root.
- **Nothing connects**: confirm your IDE is actually listening on 9003
  (`lsof -nP -i :9003` on the host) and on WSL that `WSL_IP` was exported
  before `adb up`.
- **Check from the container's side**: the container logs any failed
  connection attempts; `adb logs` after loading a page will show
  `Could not connect to debugging client` lines if Xdebug can't reach your
  IDE.

## Java debugging (JDWP)

The Java background jobs can be debugged with a remote JDWP attach on port
5005. This uses a separate overlay that is not wired into `adb`; include it
manually when starting the stack:

```shell
cd $ASPEN_DOCKER
docker compose -f docker-compose.yml -f docker-compose.debug.java.yml up -d
```

Then, from a shell in the container (`adb shell`), start the job you want to
debug with the bundled script:

```shell
/debug.sh reindexer
```

The script compiles the module and waits for a debugger to attach on port 5005
before running. Supported projects: `koha_export`, `oai_indexer`,
`overdrive_extract`, `palace_project_export`, `polaris_export`, `reindexer`,
`series_indexer`, `sideload_processing`, `sierra_export_api`,
`symphony_export`, `user_list_indexer`.

The shipped `vscodedebugconfig.json` includes a matching
**"Debug Java in Docker"** attach configuration for `localhost:5005`.
