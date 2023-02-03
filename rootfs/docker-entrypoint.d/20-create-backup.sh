#!/usr/bin/bash
set -e

# NAMED_CONF_FILE
#
NAMED_CONF_FILE="${NAMED_CONF_FILE:-/etc/bind/named.conf.local}"
NAMED_CONF_BACKUP_FILE="${NAMED_CONF_FILE}.origin"

# Create backup for NAMED_CONF_FILE
if [ ! -f "${NAMED_CONF_BACKUP_FILE}" ]; then
	cp "${NAMED_CONF_FILE}" "${NAMED_CONF_BACKUP_FILE}"
fi

# Create a new NAMED_CONF_FILE from NAMED_CONF_BACKUP_FILE everytime the system boot
rm "${NAMED_CONF_FILE}"
cp "${NAMED_CONF_BACKUP_FILE}" "${NAMED_CONF_FILE}"
