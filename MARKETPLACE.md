# Deploy and Host GLPI with Railway

GLPI is an open-source IT service management and asset management platform for help desks, inventories, contracts, licenses, data centers, and operational workflows. This template deploys the current GLPI 11 security release with MySQL, persistent storage, automatic background tasks, health checks, and safer first-boot credentials.

## About Hosting GLPI

This template runs GLPI's official Apache/PHP image and Railway MySQL as separate services connected through Railway's private network. GLPI configuration, encryption keys, uploads, logs, and marketplace plugins persist in one `/var/glpi` volume; MySQL data persists in its database volume. The official GLPI worker runs automatic actions every minute, while the included wrapper solves Railway volume permissions and disables GLPI's public default non-admin accounts.

## Common Use Cases

- IT help desk and service request management
- Hardware, software, license, and contract inventory
- CMDB and data-center infrastructure tracking
- Incident, problem, change, and project workflows
- Automated inventory collection with GLPI Agent

## Dependencies for GLPI Hosting

- GLPI 11.0.8 official container image
- Railway MySQL over private networking
- One GLPI volume mounted at `/var/glpi`
- One MySQL volume managed by Railway

## Implementation Details

The template generates separate database, root, and GLPI administrator secrets. It automatically installs GLPI, changes the built-in administrator password, disables the `tech`, `normal`, and `post-only` sample users, and exposes GLPI's `/status.php` health endpoint. The official cron worker stays enabled for scheduled mail, notifications, inventory, and cleanup tasks.

## Why Deploy GLPI on Railway?

Railway keeps the web application, database, private networking, volumes, backups, logs, and deployment history in one project. The stack stays portable because it uses GLPI's official image and standard MySQL rather than a proprietary application fork.

After deployment, sign in as `glpi` with the generated `GLPI_ADMIN_PASSWORD`, create a named super-admin, enable 2FA, and configure backups before importing production data.
