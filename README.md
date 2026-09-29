# debugcontainer

A minimal, supply-chain-hardened debug toolbox for Kubernetes and OpenShift.

Runs as non-root (UID 10001), works under restricted/OpenShift security contexts,
and pins every binary to an exact release with SHA256 verification at build time.

## Tools

|  | Tool                                                               | Version                      | Source                      |
|--|--------------------------------------------------------------------|------------------------------|-----------------------------|
|  | kubectl                                                            | v1.37.1                      | dl.k8s.io                   |
|  | k9s                                                                | v0.51.0                      | github.com/derailed/k9s     |
|  | helm                                                               | v4.3.0                       | get.helm.sh                 |
|  | oc                                                                 | 4.22.14                      | mirror.openshift.com        |
|  | mc                                                                 | RELEASE.2025-08-13T08-35-41Z | github.com/minio/mc         |
|  | rclone, vim, jq, dig, nc, traceroute, tcpdump, psql, ssh/scp, bash | —                          | Alpine 3.24 (digest-pinned) |

Base image is `alpine:3.24` pinned by manifest digest.

## Usage

```bash
docker run -it --user 10001 ghcr.io/william-rom/debugcontainer:latest /bin/bash
```

```bash
kubectl run -it --rm debug --image=ghcr.io/william-rom/debugcontainer:latest -- /bin/bash
```

Example pod with a restricted security context (works with OpenShift's strict SCCs):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: debug
      image: ghcr.io/william-rom/debugcontainer:latest
      command: ['sleep', 'infinity']
      securityContext:
        runAsUser: 10001
        runAsGroup: 0
        allowPrivilegeEscalation: false
        capabilities:
          drop: ['ALL']
```

## Supply-chain policy

- Base image pinned by digest; all external binaries pinned to exact versions and
  verified with `sha256sum -c` before install.
- No group-writable files in `PATH`; installed binaries are root-owned `0755`.
- No code downloaded at runtime; the image is self-contained.
- Home directory is group `0` with `g=u` so arbitrary UIDs (OpenShift SCCs) can write
  `$HOME` — anything running as GID 0 inside the pod can read/write files there.

## Development

Bump a tool by editing its `ARG <TOOL>_VERSION` / `ARG <TOOL>_SHA256` pair in the
`Dockerfile` (vendor checksum sources are listed at the top of the file).

CI (`.github/workflows/ci.yml`): builds the image on PRs and pushes to `main`,
fails on HIGH/CRITICAL Trivy findings, and publishes `latest` + the tag to GHCR
on `v*` tags. All actions are pinned by commit SHA.
