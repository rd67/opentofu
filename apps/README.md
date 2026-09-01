# Starter apps

Each cloud provider folder boots three tiny VMs, one per language, now
sitting **behind a load balancer** (see each provider's README for its
specific load-balancer/path-routing setup). Every VM runs a single-file,
**zero external dependency** HTTP service (stdlib only — no `npm install`,
`pip install`, or `composer install` at boot) that:

1. Listens on an HTTP port, read from the `APP_PORT` environment variable
   (defaults: `3000` Node.js, `4000` Python, `5000` PHP).
2. Opens a raw TCP connection to the MySQL host:port and the Redis host:port
   given via the `MYSQL_HOST`/`MYSQL_PORT`/`REDIS_HOST`/`REDIS_PORT`
   environment variables.
3. Returns a small JSON document reporting whether each backend was reachable.

This is intentionally a **connectivity smoke test**, not a real application —
the point of this repo is the infrastructure (networking, load balancing,
compute, managed MySQL, managed Redis) wired together correctly per cloud.
Swap `server.js` / `server.py` / `index.php` for real business logic once
the infra is in place; the systemd unit, env var wiring, and cloud-init
plumbing stay the same.

Example response from any of the three apps:

```json
{
  "app": "python",
  "hostname": "python-app-abc123",
  "mysql": { "host": "10.0.1.5", "port": 3306, "reachable": true },
  "redis": { "host": "10.0.1.6", "port": 6379, "reachable": true }
}
```

## Layout

```
apps/
├── node/
│   ├── server.js            # the app itself - plain, static Node.js, no template placeholders
│   └── cloud-init.yaml.tpl  # installs Node.js, writes server.js + env file, runs it as a systemd service
├── python/
│   ├── server.py            # plain, static Python
│   └── cloud-init.yaml.tpl
└── php/
    ├── index.php            # plain, static PHP
    ├── router.php           # PHP built-in server router - see "Path-based routing" below
    └── cloud-init.yaml.tpl
```

`server.js`, `server.py`, and `index.php` are **ordinary, unmodified**
Node.js/Python/PHP files — open them, lint them, run them locally with
`APP_PORT=3000 node server.js` etc. They contain **no OpenTofu template
placeholders at all**; every value that varies per-cloud (port, MySQL/Redis
endpoint, custom config) is supplied purely through environment variables at
runtime, read the normal way (`process.env`, `os.environ`, `getenv()`).

Only the `.yaml.tpl` cloud-init files are OpenTofu templates.

## Environment variables

Each provider wires two kinds of environment variables into every app VM,
written to `/opt/app/starter-app.env` and loaded via the systemd unit's
`EnvironmentFile=` directive:

1. **Fixed, infrastructure-derived variables** — set automatically by each
   provider's `compute.tf`, not something you configure directly:
   `APP_PORT`, `MYSQL_HOST`, `MYSQL_PORT`, `REDIS_HOST`, `REDIS_PORT`.
2. **Your own custom variables** — every provider exposes a
   `node_env` / `python_env` / `php_env` input variable
   (`type = map(string)`, default `{}`) that you can fill in
   `terraform.tfvars`, e.g.:

   ```hcl
   node_env = {
     LOG_LEVEL    = "debug"
     FEATURE_FLAG = "true"
   }
   ```

   These are merged on top of the fixed variables (so a custom var with the
   same name as a fixed one would win — avoid reusing `APP_PORT`,
   `MYSQL_HOST`, etc.) and land in the same `starter-app.env` file, so
   `process.env.LOG_LEVEL` / `os.environ["LOG_LEVEL"]` / `getenv("LOG_LEVEL")`
   just work. See each provider's README for exactly where `compute.tf`
   builds this merged map.

Nothing secret is required for the apps to work today (only a TCP
reachability check is performed, no authenticated queries), but the
mechanism is real: if you extend the apps to actually query MySQL/Redis,
route real credentials through `node_env`/`python_env`/`php_env` (or better,
a secrets manager) rather than hardcoding them.

## Path-based routing (PHP router script)

Every provider now fronts the three apps with a load balancer that routes by
path (`/nodejs*` → Node.js, `/python*` → Python, `/php*` → PHP) to a single
shared entry point - all three apps are reached the same symmetric way, no
special-cased default path. The load balancer does **not** rewrite the path
before forwarding, so a request to `/php/anything` still arrives at the PHP
app with that full path.

- Node's and Python's HTTP servers already ignore the request path and
  answer identically for any path, so they need no changes.
- PHP's built-in web server (`php -S`) instead maps the request path
  directly to a file under the docroot by default, so `/php/anything` would
  404. `router.php` fixes this: it's passed as the built-in server's router
  script (`php -S 0.0.0.0:<port> -t /opt/app /opt/app/router.php`) and
  simply `require`s `index.php` unconditionally, so every path is served the
  same way — matching Node.js/Python's behavior.

## How these templates are used

Each provider's `compute.tf` does three things per app, then renders the
cloud-init template:

```hcl
app_source_b64 = filebase64("${path.module}/../apps/node/server.js")

app_env_b64 = base64encode(join("\n", [
  for k, v in merge({
    APP_PORT   = tostring(<port>)
    MYSQL_HOST = <managed MySQL endpoint>
    MYSQL_PORT = tostring(<mysql port>)
    REDIS_HOST = <managed Redis endpoint>
    REDIS_PORT = tostring(<redis port>)
  }, var.node_env) : "${k}=${v}"
]))

user_data = templatefile("${path.module}/../apps/node/cloud-init.yaml.tpl", {
  app_source_b64 = app_source_b64
  app_env_b64    = app_env_b64
})
```

Both the app source and the env file are embedded into the cloud-init
document as base64 (`encoding: b64` in `write_files`) — this sidesteps any
YAML indentation/escaping issues from splicing arbitrary content into a YAML
block scalar. The rendered cloud-init document is passed as the VM's
user-data (`digitalocean_droplet.user_data`, `aws_instance.user_data`,
`google_compute_instance` `user-data` metadata, or
`azurerm_linux_virtual_machine.custom_data`) so the app is installed,
configured, and started automatically on first boot — no SSH or manual
provisioning step required.

The PHP variant additionally passes `app_port` directly into the cloud-init
template (not just via the env file), since it's also needed as a literal in
the systemd unit's `ExecStart` line (`php -S 0.0.0.0:<port> ...` — the
built-in server's listen address/port is a command-line argument, not
something it can read from its own environment before binding), and
`app_router_b64` (the static `router.php` content).
