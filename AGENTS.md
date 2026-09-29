## Development

Bump a tool by editing its `ARG <TOOL>_VERSION` / `ARG <TOOL>_SHA256` pair in the
`Dockerfile` (vendor checksum sources are listed at the top of the file).

CI (`.github/workflows/ci.yml`): builds the image on PRs and pushes to `main`,
reports (without failing on) HIGH/CRITICAL Trivy findings. All actions are
pinned by commit SHA.

Releases (`.github/workflows/release.yml`): release-please opens a release PR
from Conventional Commits on `main` (`feat:` bumps minor, `fix:` bumps patch).
Merging it tags `vX.Y.Z` and publishes `latest` + the tag to GHCR.
