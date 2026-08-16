#!/bin/bash
set -Eeuo pipefail
umask 077

readonly marker="${GLPI_CONFIG_DIR:-/var/glpi/config}/.railway-default-users-hardened-v1"

case "${GLPI_HARDEN_DEFAULT_USERS:-true}" in
    1|true|TRUE|yes|YES)
        if [[ ! -f "${marker}" ]]; then
            if [[ ! -f "${GLPI_CONFIG_DIR:-/var/glpi/config}/config_db.php" ]]; then
                echo >&2 "ERROR: GLPI database configuration was not created before the hardening step."
                exit 1
            fi

            if [[ -z "${GLPI_ADMIN_PASSWORD:-}" || "${#GLPI_ADMIN_PASSWORD}" -lt 20 ]]; then
                echo >&2 "ERROR: GLPI_ADMIN_PASSWORD must be set to a generated secret of at least 20 characters."
                echo >&2 "The service will not start with GLPI's public default administrator password."
                exit 1
            fi

            echo "Hardening GLPI's built-in accounts on first boot..."
            php /var/www/glpi/bin/console user:reset_password glpi \
                --password="${GLPI_ADMIN_PASSWORD}" \
                --no-interaction

            for username in tech normal post-only; do
                if ! php /var/www/glpi/bin/console user:disable "${username}" --no-interaction; then
                    echo "Built-in account '${username}' was already absent or could not be disabled; continuing."
                fi
            done

            printf 'Upstream GLPI 11.0.8 default users hardened by the Railway wrapper.\n' > "${marker}"
            chmod 0600 "${marker}"
            echo "Default-account hardening completed. Sign in as 'glpi' with GLPI_ADMIN_PASSWORD."
        fi
        ;;
    0|false|FALSE|no|NO)
        echo "Default-account hardening is disabled. This is intended only for an imported, already-hardened database."
        ;;
    *)
        echo >&2 "ERROR: GLPI_HARDEN_DEFAULT_USERS must be true or false."
        exit 1
        ;;
esac

# The bootstrap password is not required by Apache or the cron worker. Avoid
# passing it into their long-running environment after the one-time operation.
unset GLPI_ADMIN_PASSWORD

exec "$@"
