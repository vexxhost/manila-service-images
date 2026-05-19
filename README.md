# manila-service-images

This repository builds and publishes Manila generic-driver service images.

The build is intentionally small: it consumes the upstream
[`openstack/manila-image-elements`](https://github.com/openstack/manila-image-elements)
Diskimage Builder elements and preserves the Manila build command that
previously lived in Atmosphere:

```shell
disk-image-create -o manila-service-image.qcow2 \
  vm manila-ubuntu-minimal dhcp-all-interfaces manila-ssh ubuntu-nfs ubuntu-cifs
```

There are no local Diskimage Builder elements in this repository. The upstream
elements ref and commit are pinned in [`versions.env`](versions.env) so Renovate
can open a normal pull request when upstream `master` moves.

## Releases

Every push to `main` builds `manila-service-image.qcow2`, deploys a DevStack
cloud with Manila's generic driver, uploads the image as the Manila service
image, and runs one Manila Tempest test:

```text
manila_tempest_tests.tests.api.test_shares.SharesNFSTest.test_create_get_delete_share
```

If the smoke test passes, the workflow publishes the image as a GitHub release
asset. Atmosphere can later consume the image without coupling it to the
Atmosphere version by using:

```text
https://github.com/vexxhost/manila-service-images/releases/latest/download/manila-service-image.qcow2
```

## Building Locally

This project uses `uv` to install Python dependencies. On NixOS, enter a shell
with the required host tools first:

```shell
nix-shell -p uv git qemu-utils debootstrap
uv sync
uv run ./hack/build-image.sh
```

The output is `manila-service-image.qcow2` by default. You can override the
output path or upstream source metadata with environment variables:

```shell
MANILA_IMAGE_OUTPUT=out/manila-service-image.qcow2 \
MANILA_IMAGE_ELEMENTS_REF=master \
MANILA_IMAGE_ELEMENTS_COMMIT=4d63d866664ab9e45b8f08a4ff4040f9aa064c00 \
uv run ./hack/build-image.sh
```

