## Development

Bump a tool by editing its `ARG <TOOL>_VERSION` / `ARG <TOOL>_SHA256` pair in the
`Dockerfile` (vendor checksum sources are listed at the top of the file).

CI (`.github/workflows/ci.yml`): builds the image on PRs and pushes to `main`,
reports (without failing on) HIGH/CRITICAL Trivy findings, and publishes `latest` + the tag to GHCR
on `v*` tags. All actions are pinned by commit SHA.
