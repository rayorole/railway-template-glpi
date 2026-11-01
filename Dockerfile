# GLPI 11.0.8 is the current stable security release as of 2026-08-16.
# The multi-platform digest is intentionally pinned for reproducible deploys.
# Dependabot is configured to propose upstream image updates.
FROM glpi/glpi:12.0.0@sha256:ab9f66ad0e2fa03d0670df14fb7e71d35e13d985efca34c341702fe92261eaa7

LABEL org.opencontainers.image.title="GLPI on Railway" \
      org.opencontainers.image.description="Railway-ready wrapper for the official GLPI image" \
      org.opencontainers.image.source="https://github.com/glpi-project/docker-images" \
      org.opencontainers.image.version="11.0.8" \
      railway.template.upstream="glpi/glpi:11.0.8"

# Railway volumes are mounted as root. gosu lets the small bootstrap entrypoint
# repair the mount root, then execute GLPI's official entrypoint as www-data.
USER root
RUN apt-get update \
    && apt-get install --yes --no-install-recommends gosu \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 docker/railway-entrypoint.sh /usr/local/bin/railway-entrypoint
COPY --chmod=0755 docker/railway-start.sh /usr/local/bin/railway-start
COPY --chmod=0644 docker/railway-healthcheck.php /usr/local/bin/railway-healthcheck.php
COPY --chmod=0644 docker/railway-php.ini /usr/local/etc/php/conf.d/zz-railway.ini

ENV PORT=80 \
    GLPI_CRONTAB_ENABLED=1 \
    GLPI_HARDEN_DEFAULT_USERS=true \
    GLPI_REPAIR_VOLUME_PERMISSIONS=false

EXPOSE 80
STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD ["php", "/usr/local/bin/railway-healthcheck.php"]

ENTRYPOINT ["/usr/local/bin/railway-entrypoint"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
