# Upstream pins and verification

Verified on 2026-08-16.

## GLPI

- Current stable release: `11.0.8`
- Official image: `glpi/glpi:11.0.8`
- OCI multi-platform digest: `sha256:ca6b53ef948e940f41e1f4af31c001097897e819b66d146d3e5cac51ac7e9f14`
- Linux AMD64 manifest: `sha256:8e1812ed46f86e18e5f183d3c9004fa15d6bb0d90392097469ce7950a4b91cb1`
- Linux ARM64 manifest: `sha256:0fbbef25965ceead78d9eb8d5e1c8b593c14c40eecfe3d26b50f3ba0657f418c`
- Release source commit: `1056d00af818ad2a99e3009a21a9db8c724ddc53`

Verify the current registry object with:

```sh
docker buildx imagetools inspect glpi/glpi:11.0.8
```

Primary sources:

- [GLPI releases](https://github.com/glpi-project/glpi/releases)
- [Official GLPI Docker image repository](https://github.com/glpi-project/docker-images)
- [Official image tags](https://hub.docker.com/r/glpi/glpi/tags)
- [GLPI Docker instructions](https://help.glpi-project.org/tutorials/procedures/running_glpi_on_docker)

GLPI 11.0.8 is a security release containing Critical and High severity fixes. GLPI supports only the latest patch in each supported branch, so do not publish this template on an older 11.0.x patch.

The official project rebuilds supported tags regularly for base OS and PHP security updates without changing GLPI application code. A digest pin intentionally does not move. Review Dependabot's weekly Docker update PRs, back up both persistence layers, and redeploy after testing the proposed digest.

## MySQL

Railway's official MySQL template used `mysql:9.4` when this repository was prepared. The local Compose fixture pins:

- Image: `mysql:9.4`
- OCI multi-platform digest: `sha256:135bc87cce147c3d28cecb9ad270b814cb52805af7ddeea83bfcaf157d05a6b2`

The published Railway template should use Railway's maintained MySQL service rather than deriving the database from this repository.
