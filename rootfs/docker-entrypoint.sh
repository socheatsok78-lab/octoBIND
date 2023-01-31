#!/usr/bin/bash

# Bind ENV
BIND_USER="bind"
NAMED_CONF_FILE="${NAMED_CONF_FILE:-/etc/bind/named.conf.local}"
NAMED_CONF_BACKUP_FILE="${NAMED_CONF_FILE}.origin"

# Create backup for NAMED_CONF_FILE
if [ ! -f "${NAMED_CONF_BACKUP_FILE}" ]; then
    cp "${NAMED_CONF_FILE}" "${NAMED_CONF_BACKUP_FILE}"
fi

# Create a new NAMED_CONF_FILE from NAMED_CONF_BACKUP_FILE everytime the system boot
rm "${NAMED_CONF_FILE}"
cp "${NAMED_CONF_BACKUP_FILE}" "${NAMED_CONF_FILE}"

# ---

echo "Syncing rndc.key from secrets"
RNDC_KEY_FILE="${RNDC_KEY_FILE:-/var/run/secrets/rndc.key}"
if [ -f "${RNDC_KEY_FILE}" ]; then
    mv /etc/bind/rndc.key /etc/bind/rndc.key.origin
    cp "${RNDC_KEY_FILE}" /etc/bind/rndc.key
fi

# ---

# OctoDNS ENV
OCTODNS_KEY_NAME="${OCTODNS_KEY_NAME:-octodns-key}"
OCTODNS_KEY_FILE="${OCTODNS_KEY_FILE:-/etc/bind/octodns.key}"

# If OCTODNS_KEY_FILE not exists,
# Generate a new key using rndc-confgen
if [ ! -f "${OCTODNS_KEY_FILE}" ]; then
    rndc-confgen -a -k "${OCTODNS_KEY_NAME}" -c "${OCTODNS_KEY_FILE}"
fi

# Add OCTODNS_KEY to NAMED_CONF_FILE
echo "// OctoDNS Key" >> "${NAMED_CONF_FILE}"
cat "${OCTODNS_KEY_FILE}" >> "${NAMED_CONF_FILE}"
chown "${BIND_USER}:${BIND_USER}" "${NAMED_CONF_FILE}"

# ---

NS_SERVER_DOMAIN="${NS_SERVER_DOMAIN:-nameserver.local}"
NS_SERVER_ROLE=${NS_SERVER_ROLE:-primary} # role: primary or secondary

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
    NS_DATABASE="/var/lib/bind/db.${NS_SERVER_DOMAIN}"
else
    NS_DATABASE="/var/lib/bind/${NS_SERVER_DOMAIN}.saved"
fi

NS_SERVER_COUNT=${NS_SERVER_COUNT:-1}
# c=192.168.0.151
# c=192.168.0.152
# c=192.168.0.153

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
    echo "${NS_SERVER_DOMAIN}. 1800 IN NS ns${i}.${NS_SERVER_DOMAIN}." >> "${NS_DATABASE}"
done

# Add A record for NS to NS_SERVER_DOMAIN zone
for((i=1;i<="${NS_SERVER_COUNT}";i++)); do
    record="NS_SERVER_${i}_ADDR"
    record="${!record}"
    echo "ns${i}     1800    IN  A   ${record}" >> "${NS_DATABASE}"
done

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
  also-notify { ${NOTIFY_SERVER_IPS}
  };
};
EOF
else
cat <<EOF >> "${NAMED_CONF_FILE}"

// Default ${NS_SERVER_ROLE} name server zone ${NS_SERVER_DOMAIN}
zone "${NS_SERVER_DOMAIN}." {
  type ${NS_SERVER_ROLE};
  file "${NS_DATABASE}";
  primaries { ${NS_1_SERVER} key "${OCTODNS_KEY_NAME}"; };
};
EOF
fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

# Debug print
if [[ -z "${DEBUG}" ]]; then

    echo ""
    echo "Inspecting ${NS_DATABASE}:"
    cat "${NS_DATABASE}"
    echo "============================================================="
fi

# ---

# Prepare NAMED_CONF_FILE
cat <<EOF >> "${NAMED_CONF_FILE}"

//
// Add you zones here
//

EOF

AVAILABLE_ZONES="${AVAILABLE_ZONES}"
IFS=', ' read -r -a _AVAILABLE_ZONES <<< "${AVAILABLE_ZONES}"

# Loop over AVAILABLE_ZONES list
# Generate stub zone file for each domain
# Add zone to NAMED_CONF_FILE
for zone in "${_AVAILABLE_ZONES[@]}"
do

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
    ZONE_DATABASE="/var/lib/bind/db.${zone}"
else
    ZONE_DATABASE="/var/lib/bind/${zone}.saved"
fi

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
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

    # Debug print
    if [[ -z "${DEBUG}" ]]; then
        echo ""
        echo "Inspecting ${ZONE_DATABASE}:"
        cat "${ZONE_DATABASE}"
        echo "============================================================="
    fi

# Change ZONE_DATABASE ownerships
chown "${BIND_USER}:${BIND_USER}" "${ZONE_DATABASE}"
fi

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
  also-notify { ${NOTIFY_SERVER_IPS}
  };
};

EOF
# Add zone to NAMED_CONF_FILE as secondary
# Setup masters to NS_1_SERVER
else
cat <<EOF >> "${NAMED_CONF_FILE}"
// ${zone}
zone "${zone}." {
  type ${NS_SERVER_ROLE};
  file "${ZONE_DATABASE}";
  primaries { ${NS_1_SERVER} key "${OCTODNS_KEY_NAME}"; };
};

EOF
fi

done # for zone in "${_AVAILABLE_ZONES[@]}"

# Change NS_DATABASE ownerships
chown "${BIND_USER}:${BIND_USER}" "${NS_DATABASE}"

# ---

# Debug print
if [[ -z "${DEBUG}" ]]; then
    echo "Inspecting ${NAMED_CONF_FILE}:"
    cat "${NAMED_CONF_FILE}"
    echo "============================================================="
fi

# ---

# Exec Docker CMD
echo ""
exec "$@"
