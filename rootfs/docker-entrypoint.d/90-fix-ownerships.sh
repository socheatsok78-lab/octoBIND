#!/usr/bin/bash
set -eu

# Change NAMED_CONF_FILE ownerships
chown "${BIND_USER}" "${NAMED_CONF_FILE}"

# Change NS_DATABASE ownerships
if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
	NS_DATABASE="/var/lib/bind/db.${NS_SERVER_DOMAIN}"
	chown "${BIND_USER}" "${NS_DATABASE}"
fi


# Change ZONE_DATABASE ownerships
chown -R "${BIND_USER}" "/var/lib/bind"
