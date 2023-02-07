#!/usr/bin/bash
set -e

ME=$(basename $0)

OCTODNS_KEY_NAME="${OCTODNS_KEY_NAME:-octodns-key}"
OCTODNS_KEY_FILE="${OCTODNS_KEY_FILE:-/etc/bind/octodns.key}"

# If OCTODNS_KEY_FILE not exists,
# Generate a new key using rndc-confgen
if [ ! -f "${OCTODNS_KEY_FILE}" ]; then
	echo "$ME: Generating new key ${OCTODNS_KEY_NAME} to ${OCTODNS_KEY_FILE}"
	rndc-confgen -a -k "${OCTODNS_KEY_NAME}" -c "${OCTODNS_KEY_FILE}"
fi
