# syntax=docker/dockerfile:1

FROM alpine:3.24@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

# Pin every tool to an exact release and verify its SHA256 on install.
# When bumping a version, update the matching checksum from the vendor:
#   kubectl: https://dl.k8s.io/release/<ver>/bin/linux/amd64/kubectl.sha256
#   k9s:    https://github.com/derailed/k9s/releases/download/<ver>/checksums.sha256
#   helm:   https://get.helm.sh/helm-<ver>-linux-amd64.tar.gz.sha256sum
#   oc:     https://mirror.openshift.com/pub/openshift-v4/clients/ocp/<ver>/sha256sum.txt
#   mc:     asset digest from https://api.github.com/repos/minio/mc/releases/tags/<ver>
ARG KUBECTL_VERSION=v1.37.1
ARG KUBECTL_SHA256=65691ff77eb6fa44c908b77a1082c9f092c3b9733b5cefabec0d1104890e21a8
ARG K9S_VERSION=v0.51.0
ARG K9S_SHA256=c3752ad51a5a4015a113819c4eeb6e55a4d0e4b8e652494797532f6fc8161dd7
ARG HELM_VERSION=v4.3.0
ARG HELM_SHA256=86584a54def73570558f66f5111cc53dfed56689637ae32c1201205d494f54fb
ARG OC_VERSION=4.22.14
ARG OC_SHA256=7dbe8c2813bc09e18a666155eb4fa88dc3260c3832c553aa16d86c7c4277ba03
ARG MC_VERSION=RELEASE.2025-08-13T08-35-41Z
ARG MC_SHA256=01f866e9c5f9b87c2b09116fa5d7c06695b106242d829a8bb32990c00312e891

LABEL org.opencontainers.image.title="debugcontainer" \
      org.opencontainers.image.description="Minimal, supply-chain-hardened Kubernetes/OpenShift debug toolbox" \
      org.opencontainers.image.source="https://github.com/william-rom/debugcontainer"

ENV HOME=/home/debug

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Base image is digest-pinned and apk packages come from Alpine's signed
# repositories, so package-level pinning is intentionally not used here.
# hadolint ignore=DL3018
RUN apk add --no-cache \
        bash \
        bash-completion \
        bind-tools \
        ca-certificates \
        coreutils \
        curl \
        gzip \
        jq \
        netcat-openbsd \
        openssh-client-default \
        postgresql18-client \
        rclone \
        tar \
        tcpdump \
        traceroute \
        tzdata \
        vim \
    && addgroup -S -g 10001 debug \
    && adduser -S -D -h /home/debug -u 10001 -G debug debug \
    && chgrp -R 0 /home/debug \
    && chmod -R g=u /home/debug

WORKDIR /tmp

RUN set -eux; \
    curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"; \
    printf '%s  %s\n' "${KUBECTL_SHA256}" kubectl | sha256sum -c -; \
    install -m 0755 kubectl /usr/local/bin/kubectl; \
    curl -fsSLO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"; \
    printf '%s  %s\n' "${K9S_SHA256}" k9s_Linux_amd64.tar.gz | sha256sum -c -; \
    tar -xzf k9s_Linux_amd64.tar.gz k9s; \
    install -m 0755 k9s /usr/local/bin/k9s; \
    curl -fsSLO "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"; \
    printf '%s  %s\n' "${HELM_SHA256}" "helm-${HELM_VERSION}-linux-amd64.tar.gz" | sha256sum -c -; \
    tar -xzf "helm-${HELM_VERSION}-linux-amd64.tar.gz" linux-amd64/helm; \
    install -m 0755 linux-amd64/helm /usr/local/bin/helm; \
    curl -fsSLO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OC_VERSION}/openshift-client-linux-${OC_VERSION}.tar.gz"; \
    printf '%s  %s\n' "${OC_SHA256}" "openshift-client-linux-${OC_VERSION}.tar.gz" | sha256sum -c -; \
    tar -xzf "openshift-client-linux-${OC_VERSION}.tar.gz" oc; \
    install -m 0755 oc /usr/local/bin/oc; \
    curl -fsSLO "https://github.com/minio/mc/releases/download/${MC_VERSION}/mc.linux-amd64.${MC_VERSION}"; \
    printf '%s  %s\n' "${MC_SHA256}" "mc.linux-amd64.${MC_VERSION}" | sha256sum -c -; \
    install -m 0755 "mc.linux-amd64.${MC_VERSION}" /usr/local/bin/mc; \
    rm -rf /tmp/*; \
    kubectl version --client; \
    k9s version; \
    helm version --short; \
    oc version; \
    mc --version

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

USER 10001
WORKDIR /home/debug

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
