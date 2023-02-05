#!/usr/bin/bash
set -e

NS_KEY_NAME="${NS_KEY_NAME:-ns-primary-key}"
NS_KEY_FILE="${NS_KEY_FILE:-/etc/bind/ns-sync.key}"

# If NS_KEY_FILE not exists,
# Generate a new key using rndc-confgen
if [ ! -f "${NS_KEY_FILE}" ]; then
	echo " - Generating new key ${NS_KEY_FILE} to ${NS_KEY_FILE}"
	rndc-confgen -a -k "${NS_KEY_NAME}" -c "${NS_KEY_FILE}"
fi

# Add NS_KEY_FILE to NAMED_CONF_FILE
echo " - Loading ${NS_KEY_NAME} key from ${NS_KEY_FILE}"
echo "// Nameserver Key" >> "${NAMED_CONF_FILE}"
cat "${NS_KEY_FILE}" >> "${NAMED_CONF_FILE}"

if [ ! -f "${NS_KEY_FILE}" ]; then
    cp "${NS_KEY_FILE}" "/etc/bind"
fi
