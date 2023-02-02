#!/usr/bin/bash
set -eu

NS_SERVER_DOMAIN="${NS_SERVER_DOMAIN:-nameserver.corpnet}"
NS_SERVER_ROLE=${NS_SERVER_ROLE:-primary} # role: primary or secondary

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
	NS_DATABASE="/var/lib/bind/db.${NS_SERVER_DOMAIN}"
else
	NS_DATABASE="/var/lib/bind/${NS_SERVER_DOMAIN}.saved"
fi

NS_SERVER_COUNT=${NS_SERVER_COUNT:-1}
# NS_SERVER_1_ADDR=192.168.0.151
# NS_SERVER_2_ADDR=192.168.0.152
# NS_SERVER_3_ADDR=192.168.0.153

# Notify Name Server IP Addresses
NOTIFY_SERVER_IPS=""
for((i=2;i<="${NS_SERVER_COUNT}";i++)); do
	record="NS_SERVER_${i}_ADDR"
	record="${!record}"

	NOTIFY_SERVER_IPS="${NOTIFY_SERVER_IPS}
	${record} key \"${OCTODNS_KEY_NAME}\";"
done

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

# Generate NS_SERVER_DOMAIN zone
cat <<EOF > "${NS_DATABASE}"
\$ORIGIN ${NS_SERVER_DOMAIN}.
\$TTL 1800
${NS_SERVER_DOMAIN}. IN SOA ns1.${NS_SERVER_DOMAIN}. hostmaster.${NS_SERVER_DOMAIN}. (
							1       ; serial
							3h      ; refresh (3 hours)
							1h      ; retry (1 hour)
							1w      ; expire (1 week)
							30m     ; minimum (30 minutes)
							)
EOF

# Add NS record to NS_SERVER_DOMAIN zone
for((i=1;i<="${NS_SERVER_COUNT}";i++)); do
	record="NS_SERVER_${i}_ADDR"
	record="${!record}"
	echo "${NS_SERVER_DOMAIN}.		1800	IN	NS	ns${i}.${NS_SERVER_DOMAIN}." >> "${NS_DATABASE}"
done

# Add A record for NS to NS_SERVER_DOMAIN zone
for((i=1;i<="${NS_SERVER_COUNT}";i++)); do
	record="NS_SERVER_${i}_ADDR"
	record="${!record}"
	echo "ns${i}				1800	IN	A	${record}" >> "${NS_DATABASE}"
done

NOTIFY_SERVER_IPS_BLOCK=""
if [[ -n "${NOTIFY_SERVER_IPS}" ]]; then
	NOTIFY_SERVER_IPS_BLOCK="also-notify { ${NOTIFY_SERVER_IPS} };"
fi


# Add primary NS_SERVER_DOMAIN zone config to NAMED_CONF_FILE
cat <<EOF >> "${NAMED_CONF_FILE}"

// Default ${NS_SERVER_ROLE} name server zone ${NS_SERVER_DOMAIN}
zone "${NS_SERVER_DOMAIN}." {
	type ${NS_SERVER_ROLE};
	file "${NS_DATABASE}";
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

else

# Add primary NS_SERVER_DOMAIN zone config to NAMED_CONF_FILE
cat <<EOF >> "${NAMED_CONF_FILE}"

// Default ${NS_SERVER_ROLE} name server zone ${NS_SERVER_DOMAIN}
zone "${NS_SERVER_DOMAIN}." {
	type ${NS_SERVER_ROLE};
	file "${NS_DATABASE}";
	primaries { ${NS_SERVER_1_ADDR} key "${OCTODNS_KEY_NAME}"; };
};
EOF

fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
