#!/bin/bash
set -Eeuo pipefail

readonly glpi_volume="/var/glpi"

if [[ "$(id -u)" -ne 0 ]]; then
    echo >&2 "ERROR: Railway's GLPI volume bootstrap must start as root."
    echo >&2 "Do not override the image user; this script drops to www-data before GLPI starts."
    exit 1
fi

if [[ -n "${RAILWAY_VOLUME_MOUNT_PATH:-}" && "${RAILWAY_VOLUME_MOUNT_PATH}" != "${glpi_volume}" ]]; then
    echo >&2 "ERROR: Attach the GLPI volume at ${glpi_volume}; Railway reports ${RAILWAY_VOLUME_MOUNT_PATH}."
    exit 1
fi

# Change only the mount root during normal starts. A fresh, empty volume then
# gets all subdirectories from the official entrypoint under www-data ownership.
mkdir -p -- "${glpi_volume}"
chown www-data:www-data "${glpi_volume}"
chmod u+rwx "${glpi_volume}"

case "${GLPI_REPAIR_VOLUME_PERMISSIONS:-false}" in
    1|true|TRUE|yes|YES)
        echo "Repairing ownership below ${glpi_volume}; this can take time on large volumes."
        find "${glpi_volume}" -xdev -exec chown www-data:www-data {} +
        ;;
esac

# Keep all upstream initialization logic. railway-start runs only after the
# official image has waited for MySQL and installed or upgraded the database.
exec gosu www-data /opt/glpi/entrypoint.sh /usr/local/bin/railway-start "$@"
