# Railway template composer settings

Railway templates are composed in the Railway UI; `railway.toml` configures the GLPI source service but cannot declare the second service. Use these settings when creating the publishable template.

## Service 1: MySQL

Add Railway's official **MySQL** database service and keep the service name exactly `MySQL` so the reference variables below resolve.

Before its first deployment, configure a dedicated GLPI database and user:

| Variable | Template value | Description |
|---|---|---|
| `MYSQL_DATABASE` | `glpi` | Database created on first boot. |
| `MYSQL_USER` | `glpi` | Dedicated application user; do not use root from GLPI. |
| `MYSQL_PASSWORD` | `${{ secret(40, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") }}` | Generated GLPI database password. |
| `MYSQL_ROOT_PASSWORD` | `${{ secret(48, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") }}` | Separate generated administrative password. |
| `MYSQLHOST` | `${{ RAILWAY_PRIVATE_DOMAIN }}` | Private Railway hostname. |
| `MYSQLPORT` | `3306` | Internal MySQL port. |
| `MYSQLDATABASE` | `${{ MYSQL_DATABASE }}` | Stable reference exposed to GLPI. |
| `MYSQLUSER` | `${{ MYSQL_USER }}` | Stable reference exposed to GLPI. |
| `MYSQLPASSWORD` | `${{ MYSQL_PASSWORD }}` | Stable reference exposed to GLPI. |
| `MYSQL_URL` | `mysql://${{ MYSQL_USER }}:${{ MYSQL_PASSWORD }}@${{ RAILWAY_PRIVATE_DOMAIN }}:3306/${{ MYSQL_DATABASE }}` | Convenience URL for Railway's database tools. |

Attach the database volume at `/var/lib/mysql`. Keep one replica. GLPI does not require public MySQL networking, so do not add a public TCP proxy unless the deployer explicitly needs external administration.

These initialization variables only create the database/user on an empty MySQL volume. Do not add them later to an already-initialized database and expect MySQL to create the user.

## Service 2: GLPI

Use this repository as a GitHub source service. Attach exactly one volume at `/var/glpi`, enable HTTP public networking on target port `80`, and configure:

| Variable | Template value | Description |
|---|---|---|
| `PORT` | `80` | The official image's Apache port and Railway healthcheck port. |
| `GLPI_DB_HOST` | `${{MySQL.MYSQLHOST}}` | Private MySQL hostname. |
| `GLPI_DB_PORT` | `${{MySQL.MYSQLPORT}}` | Private MySQL port. |
| `GLPI_DB_NAME` | `${{MySQL.MYSQLDATABASE}}` | Database name. |
| `GLPI_DB_USER` | `${{MySQL.MYSQLUSER}}` | Dedicated application user. |
| `GLPI_DB_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` | Database password reference. |
| `GLPI_ADMIN_PASSWORD` | `A1a-${{ secret(36, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") }}` | One-time password for the built-in `glpi` administrator. Required by the wrapper. The fixed prefix satisfies common complexity rules. |
| `GLPI_HARDEN_DEFAULT_USERS` | `true` | Changes the `glpi` password and disables `tech`, `normal`, and `post-only` once. |
| `GLPI_CRONTAB_ENABLED` | `1` | Runs GLPI automatic actions every minute in the official image. |
| `GLPI_SKIP_AUTOINSTALL` | `false` | Enables unattended first installation. |
| `GLPI_SKIP_AUTOUPDATE` | `false` | Runs schema updates when the pinned image is deliberately updated. |

Add descriptions to every variable in the composer. Seal the generated password values after confirming the initial deployment. The GLPI service must remain at one replica because it has a volume and includes one cron worker.

The settings committed in `railway.toml` provide:

- `/status.php` healthcheck with a 600-second first-install timeout;
- required `/var/glpi` mount;
- one replica and no app sleeping;
- on-failure restarts and a 30-second drain window.

## First-deploy acceptance check

1. MySQL becomes healthy and GLPI logs show the database installation completed.
2. GLPI logs show `Default-account hardening completed`.
3. `/status.php` returns HTTP 200 and JSON with `glpi.status` equal to `OK` or `WARNING`.
4. Sign in with username `glpi` and the generated `GLPI_ADMIN_PASSWORD` value.
5. Change the administrator password, configure 2FA, and create a named super-admin before normal use.
6. Configure Railway backups for both the MySQL volume and `/var/glpi`.

For an imported existing GLPI database, set `GLPI_HARDEN_DEFAULT_USERS=false` for the first boot. The wrapper must not assume an imported instance still has the built-in accounts.
