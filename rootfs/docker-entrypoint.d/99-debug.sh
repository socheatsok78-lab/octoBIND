#!/usr/bin/bash
set -eu

echo "=================================================="
echo "Showing ${OCTODNS_KEY_FILE}:"
echo "=================================================="
cat "${OCTODNS_KEY_FILE}"
echo ""

echo "=================================================="
echo "Showing ${NAMED_OPTIONS_FILE}:"
echo "=================================================="
cat "${NAMED_OPTIONS_FILE}"
echo ""

echo "=================================================="
echo "Showing ${NAMED_CONF_FILE}:"
echo "=================================================="
cat "${NAMED_CONF_FILE}"
