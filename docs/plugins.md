# Plugins

The dev box can mount a directory of Aspen plugin checkouts into the container
and switch on Aspen's plugin loading:

```shell
adb up --plugins
adb up --plugins --plugins-path ~/my-aspen-plugins
```

## How it works

The plugins overlay (`docker-compose.plugins.yml`) bind-mounts your plugins
directory at `/plugins` inside the main container and sets
`ASPEN_PLUGINS_ENABLED=1`. On startup the entrypoint then appends to the site
`config.ini`:

```ini
[Plugins]
enabled = 1
path = /plugins
```

The host directory is resolved in this order:

1. `--plugins-path` (made absolute)
2. the `ASPEN_PLUGINS` environment variable (can also be set in `.env`)
3. `$ASPEN_DOCKER/plugins`

Each plugin is a subdirectory with a PHP file of the same name inside:
`/plugins/MyPlugin/MyPlugin.php` containing class `MyPlugin`. Aspen loads
every plugin it finds in the mounted directory. Edits on the host take effect
straight away.
