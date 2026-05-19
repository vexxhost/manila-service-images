#!/usr/bin/env bash

set -euo pipefail

TEMPEST_DIR=${TEMPEST_DIR:-/opt/stack/tempest}
TEMPEST_TEST_REGEX=${TEMPEST_TEST_REGEX:-manila_tempest_tests.tests.api.test_shares.SharesNFSTest.test_create_get_delete_share}

cd "${TEMPEST_DIR}"
tox -e all -- "${TEMPEST_TEST_REGEX}"

