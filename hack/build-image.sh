#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

env_MANILA_IMAGE_ELEMENTS_REPOSITORY=${MANILA_IMAGE_ELEMENTS_REPOSITORY:-}
env_MANILA_IMAGE_ELEMENTS_REF=${MANILA_IMAGE_ELEMENTS_REF:-}
env_MANILA_IMAGE_ELEMENTS_COMMIT=${MANILA_IMAGE_ELEMENTS_COMMIT:-}
env_MANILA_IMAGE_RELEASE=${MANILA_IMAGE_RELEASE:-}

# shellcheck disable=SC1091
source "${ROOT_DIR}/versions.env"

MANILA_IMAGE_ELEMENTS_REPOSITORY=${env_MANILA_IMAGE_ELEMENTS_REPOSITORY:-${MANILA_IMAGE_ELEMENTS_REPOSITORY}}
MANILA_IMAGE_ELEMENTS_REF=${env_MANILA_IMAGE_ELEMENTS_REF:-${MANILA_IMAGE_ELEMENTS_REF}}
MANILA_IMAGE_ELEMENTS_COMMIT=${env_MANILA_IMAGE_ELEMENTS_COMMIT:-${MANILA_IMAGE_ELEMENTS_COMMIT:-}}
MANILA_IMAGE_RELEASE=${env_MANILA_IMAGE_RELEASE:-${MANILA_IMAGE_RELEASE}}

: "${MANILA_IMAGE_ELEMENTS_REPOSITORY:?}"
: "${MANILA_IMAGE_ELEMENTS_REF:?}"
: "${MANILA_IMAGE_RELEASE:?}"

MANILA_IMAGE_NAME=${MANILA_IMAGE_NAME:-manila-service-image}
MANILA_IMAGE_OUTPUT=${MANILA_IMAGE_OUTPUT:-${ROOT_DIR}/${MANILA_IMAGE_NAME}.qcow2}
MANILA_IMAGE_ARCH=${MANILA_IMAGE_ARCH:-amd64}
MANILA_USER=${MANILA_USER:-manila}
MANILA_PASSWORD=${MANILA_PASSWORD:-manila}
MANILA_USER_AUTHORIZED_KEYS=${MANILA_USER_AUTHORIZED_KEYS:-None}
DHCP_TIMEOUT=${DHCP_TIMEOUT:-300}

if [[ "${MANILA_IMAGE_OUTPUT}" == *.qcow2 ]]; then
    output_base=${MANILA_IMAGE_OUTPUT%.qcow2}
else
    output_base=${MANILA_IMAGE_OUTPUT}
fi

mkdir -p "$(dirname "${output_base}")"

workdir=$(mktemp -d)
cleanup() {
    if [[ "${KEEP_WORKDIR:-0}" == "1" ]]; then
        echo "Keeping work directory: ${workdir}"
        return
    fi
    rm -rf "${workdir}"
}
trap cleanup EXIT

checkout="${workdir}/manila-image-elements"
git clone --branch "${MANILA_IMAGE_ELEMENTS_REF}" --single-branch \
    "${MANILA_IMAGE_ELEMENTS_REPOSITORY}" "${checkout}"

if [[ -n "${MANILA_IMAGE_ELEMENTS_COMMIT:-}" ]]; then
    if ! git -C "${checkout}" checkout --detach "${MANILA_IMAGE_ELEMENTS_COMMIT}"; then
        git -C "${checkout}" fetch --depth 1 origin "${MANILA_IMAGE_ELEMENTS_COMMIT}"
        git -C "${checkout}" checkout --detach "${MANILA_IMAGE_ELEMENTS_COMMIT}"
    fi
fi

export ELEMENTS_PATH="${checkout}/elements"
export DIB_DEFAULT_INSTALLTYPE=package
export DIB_RELEASE="${MANILA_IMAGE_RELEASE}"
export DIB_MANILA_USER_USERNAME="${MANILA_USER}"
export DIB_MANILA_USER_PASSWORD="${MANILA_PASSWORD}"
export DIB_MANILA_USER_AUTHORIZED_KEYS="${MANILA_USER_AUTHORIZED_KEYS}"
export DIB_DHCP_TIMEOUT="${DHCP_TIMEOUT}"

read -r -a extra_dib_args <<< "${DIB_EXTRA_ARGS:-}"

disk-image-create \
    -t qcow2 \
    -a "${MANILA_IMAGE_ARCH}" \
    -o "${output_base}" \
    "${extra_dib_args[@]}" \
    vm manila-ubuntu-minimal dhcp-all-interfaces manila-ssh ubuntu-nfs ubuntu-cifs

test -f "${output_base}.qcow2"
