#!/usr/bin/bash
set -eu

# OctoDNS ENV
OCTODNS_KEY_NAME="${OCTODNS_KEY_NAME:-octodns-key}"
OCTODNS_KEY_FILE="${OCTODNS_KEY_FILE:-/etc/bind/octodns.key}"

# If OCTODNS_KEY_FILE not exists,
# Generate a new key using rndc-confgen
if [ ! -f "${OCTODNS_KEY_FILE}" ]; then
	echo " - Generating new key ${OCTODNS_KEY_NAME} to ${OCTODNS_KEY_FILE}"
	rndc-confgen -a -k "${OCTODNS_KEY_NAME}" -c "${OCTODNS_KEY_FILE}"
fi

# Add OCTODNS_KEY to NAMED_CONF_FILE
echo " - Loading ${OCTODNS_KEY_NAME} key from ${OCTODNS_KEY_FILE}"
echo "// OctoDNS Key" >> "${NAMED_CONF_FILE}"
cat "${OCTODNS_KEY_FILE}" >> "${NAMED_CONF_FILE}"

echo " - Fixing ${OCTODNS_KEY_FILE} permission"
chown "${BIND_USER}" "${NAMED_CONF_FILE}"
