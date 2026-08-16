# Deploy and Host GLPI with Railway

A production-oriented Railway wrapper around GLPI's official Docker image. It deploys GLPI with Railway MySQL, one persistent `/var/glpi` volume, the official background worker, and a first-boot credential hardening step.

## What is pinned

- GLPI `11.0.8`, the current stable security release as verified on 2026-08-16
- Official `glpi/glpi:11.0.8` image at immutable multi-platform digest `sha256:ca6b53ef948e940f41e1f4af31c001097897e819b66d146d3e5cac51ac7e9f14`
- MySQL `9.4` in the local Compose fixture, matching Railway's official MySQL template when prepared

See [UPSTREAM.md](UPSTREAM.md) for manifests and primary sources.

## Architecture

```text
Internet
   |
Railway HTTPS
   |
GLPI :80  ---- private network ---->  MySQL :3306
   |                                      |
/var/glpi volume                    /var/lib/mysql volume
```

The GLPI volume contains configuration, `glpicrypt.key`, uploads and documents, logs, caches, sessions, and marketplace plugins. Application source remains immutable in the image.

## Publish as a Railway template

Use [TEMPLATE_SETUP.md](TEMPLATE_SETUP.md) for the exact two-service composer settings, generated secrets, reference variables, volume paths, and acceptance checks. `railway.toml` configures only the repository-backed GLPI service; Railway's template composer is still needed to add MySQL.

Important defaults:

- GLPI listens on port `80`; set `PORT=80` so Railway probes the correct port.
- Attach one GLPI volume at `/var/glpi`.
- Keep GLPI at one replica. Railway volumes do not support replicas, and multiple cron workers would duplicate automatic tasks.
- Do not enable app sleeping. GLPI's mail, notification, inventory, and cleanup jobs need the built-in worker to run continuously.
- Do not expose MySQL publicly unless there is a specific administrative need.

## Secure first boot

GLPI normally installs four public default accounts. This wrapper requires `GLPI_ADMIN_PASSWORD` to be a generated secret of at least 20 characters, resets the `glpi` administrator to it, disables `tech`, `normal`, and `post-only`, then writes a marker under the persistent config directory. It does not repeat the operation on restart.

Sign in with:

- Username: `glpi`
- Password: the Railway `GLPI_ADMIN_PASSWORD` value

Create a named super-admin, enable 2FA, and rotate the bootstrap password immediately. After the marker exists, the bootstrap variable can be removed; it is unset before Apache and the cron worker start.

For an imported and already-hardened database, set `GLPI_HARDEN_DEFAULT_USERS=false` before its first start with this image.

## Why there is a wrapper entrypoint

The official image correctly runs as `www-data`, but Railway mounts volumes as root. The wrapper starts as root, checks that Railway mounted exactly `/var/glpi`, changes only that directory's owner, and immediately uses `gosu` to execute GLPI's unmodified official entrypoint as `www-data`. Apache, installation/update commands, and the cron worker never run as root.

If restored files have incorrect ownership, temporarily set `GLPI_REPAIR_VOLUME_PERMISSIONS=true` for one deployment. Remove it after a successful start; recursively scanning a large volume adds startup time.

## Installation and background tasks

The five official database variables must all be present:

- `GLPI_DB_HOST`
- `GLPI_DB_PORT`
- `GLPI_DB_NAME`
- `GLPI_DB_USER`
- `GLPI_DB_PASSWORD`

With `GLPI_SKIP_AUTOINSTALL=false`, the official entrypoint waits up to 120 seconds for MySQL and installs an empty database. With `GLPI_SKIP_AUTOUPDATE=false`, it runs GLPI's schema update when a deliberately newer image is deployed.

`GLPI_CRONTAB_ENABLED=1` starts the official supervisor-managed worker, which invokes `front/cron.php` every minute. In GLPI, configure relevant automatic actions for **CLI** mode; GLPI mode depends on user traffic.

## Health checks

Railway probes GLPI's official `/status.php` endpoint and allows 600 seconds for a first installation. This exercises Apache, PHP, GLPI bootstrap, its database connection, filesystem, cron state, and configured integrations.

The Docker image also has a continuous container healthcheck. It accepts GLPI `OK` and `WARNING`, but fails on `PROBLEM`, malformed JSON, a non-200 response, or an unreachable endpoint. Railway currently uses its HTTP healthcheck only during deployment, so configure external uptime monitoring for continuous alerting.

## Backups and upgrades

Back up both the MySQL service and `/var/glpi` before every update. A complete recovery needs the database and GLPI volume from the same point in time; `glpicrypt.key` in the config directory is required to decrypt stored secrets.

Upgrade procedure:

1. Review the GLPI release notes and plugin compatibility.
2. Create or verify Railway backups for both volumes.
3. Update the version and digest in `Dockerfile` through a reviewed Dependabot PR or manual change.
4. Test against a restored copy when the instance is important.
5. Redeploy. The official entrypoint runs `database:update` because auto-update is enabled.
6. Verify `/status.php`, deployment logs, login, cron tasks, mail, inventory, and plugins.

Do not roll back only the application image after a database migration. Restore a matching pre-upgrade database and `/var/glpi` snapshot. Major upgrades require extra care; never assume third-party plugins are compatible.

Digest pinning prevents silent image changes, but it also prevents automatic intake of GLPI's weekly base-image security rebuilds. Review dependency updates promptly. GLPI supports only the newest patch in each supported branch.

## Local validation

Docker Compose is for local testing only:

```sh
cp .env.example .env
docker compose up --build
```

Open `http://localhost:8080`, then check:

```sh
curl --fail http://localhost:8080/status.php
docker compose exec glpi php bin/console system:status
docker compose ps
```

Stop the test stack with `docker compose down`. Adding `--volumes` permanently deletes the local test data.

## Operational notes

- Increase PHP upload limits in `docker/railway-php.ini` only after considering Railway memory and request limits.
- GLPI 11.0.7+ supports the official `GLPI_DB_SSL*` variables for external TLS databases. Railway private networking does not require them for this template.
- The plugin marketplace directory is already inside `/var/glpi` for GLPI 11.
- Railway services with volumes have brief downtime during redeploy because the same volume cannot be mounted to overlapping deployments.
- Sealed secrets are not copied into duplicated or PR environments. A fresh volume without `GLPI_ADMIN_PASSWORD` fails closed rather than exposing GLPI's defaults.

## Upstream documentation

- [Official GLPI Docker image](https://github.com/glpi-project/docker-images)
- [Running GLPI on Docker](https://help.glpi-project.org/tutorials/procedures/running_glpi_on_docker)
- [GLPI automatic actions](https://help.glpi-project.org/documentation/modules/configuration/crontasks)
- [GLPI update procedure](https://help.glpi-project.org/tutorials/procedures/updating-glpi)
- [Railway MySQL](https://docs.railway.com/databases/mysql)
- [Railway volumes](https://docs.railway.com/volumes)
- [Railway template best practices](https://docs.railway.com/templates/best-practices)

This repository is not affiliated with Teclib' or the GLPI project. GLPI is GPL-3.0 licensed; this repository references its official image and does not vendor GLPI source.
