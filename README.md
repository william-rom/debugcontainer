# debugcontainer

A minimal, supply-chain-hardened debug toolbox for Kubernetes and OpenShift.

Runs as non-root (UID 10001), works under restricted/OpenShift security contexts,
and pins every binary to an exact release with SHA256 verification at build time.

## Tools

| Tool                                                               | Version                      | Source                      | Verification               |
|--------------------------------------------------------------------|------------------------------|-----------------------------|----------------------------|
| kubectl                                                            | v1.37.1                      | dl.k8s.io                   | published `.sha256`        |
| k9s                                                                | v0.51.0                      | github.com/derailed/k9s     | release `checksums.sha256` |
| helm                                                               | v4.3.0                       | get.helm.sh                 | published `.sha256sum`     |
| oc                                                                 | 4.22.14                      | mirror.openshift.com        | release `sha256sum.txt`    |
| mc                                                                 | RELEASE.2025-08-13T08-35-41Z | github.com/minio/mc         | GitHub asset digest        |
| rclone, vim, jq, dig, nc, traceroute, tcpdump, psql, ssh/scp, bash | —                            | Alpine 3.24 (digest-pinned) | signed apk repos           |

## Usage

```bash
kubectl run -it --rm debug --image=ghcr.io/william-rom/debugcontainer:latest
```

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

