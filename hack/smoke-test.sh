#!/usr/bin/env bash

set -euo pipefail

TEMPEST_DIR=${TEMPEST_DIR:-/opt/stack/tempest}
TEMPEST_BIN=${TEMPEST_BIN:-/opt/stack/data/venv/bin/tempest}
TEMPEST_CONFIG=${TEMPEST_CONFIG:-${TEMPEST_DIR}/etc/tempest.conf}
TEMPEST_TEST_REGEX=${TEMPEST_TEST_REGEX:-manila_tempest_tests.tests.api.test_shares.SharesNFSTest.test_create_get_delete_share}

export TEMPEST_CONFIG

cd "${TEMPEST_DIR}"
"${TEMPEST_BIN}" list-plugins
"${TEMPEST_BIN}" run --regex "${TEMPEST_TEST_REGEX}"
