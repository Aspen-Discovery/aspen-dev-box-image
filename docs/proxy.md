# Aspen Proxy

The aspen proxy replaces per-stack port bindings with
a hostname routing container: every stack attaches to one external Docker network
(`aspen-proxy`) and a Traefik instance routes `<name>.localhost`
hostnames to the right container.

It is separate from koha-testing-docker's proxy (`KTD_PROXY=yes`):

- The aspen traefik only routes containers labelled `aspen.proxy=true`
  (enforced with a provider constraint), so it only picks up the correct containers.
- Both proxies run side by side: the aspen proxy defaults to aspen's usual
  port 8083 (8443 for TLS), leaving 80/443 to KTD's. Override with
  `PROXY_HTTP_PORT` / `PROXY_HTTPS_PORT`; `adb` detects the published port
  and uses it in the instance URLs.

## Proxy lifecycle

`adb` manages the proxy automatically: `adb up` starts it when it isn't
running and `adb down` stops it along with the last proxied stack
(`adb down --all` brings down every aspen stack and the proxy). For manual
control:

```shell
adb proxy up
```

The Traefik dashboard is served on its own port at
[localhost:8090/dashboard/](http://localhost:8090/dashboard/). Override the
port with `PROXY_DASHBOARD_PORT`.

## Proxying an Aspen stack

Layer `compose/docker-compose.proxied-instance.yml` onto the base compose file. It drops
the host port bindings, joins the `aspen-proxy` network and labels the web
container for Traefik. It needs two env vars and accepts two more:

| Variable | Required | Purpose |
| ---------- | ---------- | --------- |
| `ASPEN_STACK` | yes | compose project name; namespaces the Traefik router (`aspen-<stack>`) |
| `ASPEN_HOST` | yes | hostname to serve, e.g. `mybranch.localhost` |
| `ASPEN_URL` | no | full base URL (default `http://<ASPEN_HOST>`) |
| `ASPEN_PROXY_ENTRYPOINT` | no | `web` (default) or `websecure` |
| `ASPEN_PROXY_TLS` | no | enable TLS on the router (default `false`) |

`SITE_NAME` and `URL` inside the container are derived from `ASPEN_HOST` and
`ASPEN_URL`, so they do not need to be set separately.

`adb up` handles all of this: when the aspen proxy is running the
overlay is layered in automatically and the stack is served on
`http://<stack>.localhost:port` with the default being 8083 for the aspen container, 8084 for solr;
when the proxy isn't running it falls back to host ports. `--no-proxy` forces
host ports, `--host` overrides the hostname.

```shell
adb up -d
```

Combined with git worktrees of the aspen clone (`adb -w`) this gives one URL
per branch:

```shell
git -C $ASPEN_CLONE worktree add ../aspen-my-feature my-feature
adb -w my-feature up -d           # http://aspen-my-feature.localhost:8083
```

`localhost` names resolve to loopback, so the instance URLs need no DNS
or `/etc/hosts` changes.

## Library subdomains

The router matches the instance host and any subdomain of it, so an aspen
instance serving several libraries on subdomains works through the proxy:
`lib1.mybranch.localhost` and `lib2.mybranch.localhost` reach the same
container and aspen selects the interface from the Host header. Locally this
functionality needs no additional setup.

## Linking each Aspen to its own Koha

Proxying and Koha linking are independent: `compose/docker-compose.koha.yml`
and `ils/koha.yml` resolve everything about the Koha connection (network,
hostnames, database name and user) from `KOHA_STACK`, the compose project
name of the KTD instance, over that instance's `kohanet` network, not
through either proxy. Start several KTD instances under different
`KOHA_INSTANCE` names and point each Aspen at its own with
`adb up --koha-stack <name>`.
