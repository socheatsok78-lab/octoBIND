#!/usr/bin/bash
set -e

# Notify Name Server IP Addresses
NOTIFY_SERVER_IPS=""
for((i=2;i<="${NS_SERVER_COUNT}";i++)); do
	record="NS_SERVER_${i}_ADDR"
	record="${!record}"

	NOTIFY_SERVER_IPS="${NOTIFY_SERVER_IPS}
	${record} key \"${OCTODNS_KEY_NAME}\";"
done

NOTIFY_SERVER_IPS_BLOCK=""
if [[ -n "${NOTIFY_SERVER_IPS}" ]]; then
	NOTIFY_SERVER_IPS_BLOCK="also-notify { ${NOTIFY_SERVER_IPS} };"
fi

# Prepare NAMED_CONF_FILE
cat <<EOF >> "${NAMED_CONF_FILE}"

//
// Add you zones here
//

EOF

ZONES_AVAILABLE="${ZONES_AVAILABLE}"
IFS=', ' read -r -a _ZONES_AVAILABLE <<< "${ZONES_AVAILABLE}"

# Loop over ZONES_AVAILABLE list
# Generate stub zone file for each domain
# Add zone to NAMED_CONF_FILE
for zone in "${_ZONES_AVAILABLE[@]}"
do

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
	ZONE_DATABASE="/var/lib/bind/db.${zone}"
else
	ZONE_DATABASE="/var/lib/bind/${zone}.saved"
fi

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
# Do not override existing zone file
# Existing zone file might contain updated records
if [ ! -f "${ZONE_DATABASE}" ]; then
# cat <<EOF > "${ZONE_DATABASE}"
cat <<EOF > "${ZONE_DATABASE}"
\$ORIGIN .
\$TTL 1800	; 30 minutes
${zone}	IN SOA	ns1.${NS_SERVER_DOMAIN}. hostmaster.${zone}. (
				1       ; serial
				3h      ; refresh (3 hours)
				1h      ; retry (1 hour)
				1w      ; expire (1 week)
				30m     ; minimum (30 minutes)
				)
EOF
# cat <<EOF > "${ZONE_DATABASE}"

# Add NS record to zone
for((i=1;i<="${NS_SERVER_COUNT}";i++)); do
	echo "			NS ns${i}.${NS_SERVER_DOMAIN}." >> "${ZONE_DATABASE}"
done

fi # if [ ! -f "${ZONE_DATABASE}" ]; then
fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

# Add zone to NAMED_CONF_FILE as primary
# Setup allow-transfer for OCTODNS_KEY_NAME and NS${i}_ADDR
if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
cat <<EOF >> "${NAMED_CONF_FILE}"
// ${zone}
zone "${zone}." {
	type ${NS_SERVER_ROLE};
	file "${ZONE_DATABASE}";
	notify yes;
	allow-transfer {
		key "${OCTODNS_KEY_NAME}"; # AXFR
	};
	allow-update {
		key "${OCTODNS_KEY_NAME}"; # RFC 2136
	};
	${NOTIFY_SERVER_IPS_BLOCK}
};

EOF
# Add zone to NAMED_CONF_FILE as secondary
# Setup masters to NS_SERVER_1_ADDR
else
cat <<EOF >> "${NAMED_CONF_FILE}"
// ${zone}
zone "${zone}." {
	type ${NS_SERVER_ROLE};
	file "${ZONE_DATABASE}";
	primaries { ${NS_SERVER_1_ADDR} key "${OCTODNS_KEY_NAME}"; };
};

EOF
fi

echo " - ${zone} => ${ZONE_DATABASE}"

done # for zone in "${_ZONES_AVAILABLE[@]}"
