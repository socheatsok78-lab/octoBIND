#!/usr/bin/bash

# Bind ENV
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

# ---

NS_DOMAIN="${NS_DOMAIN:-nameserver.local}"
NS_ROLE=${NS_ROLE:-primary} # role: primary or secondary
NS_DATABASE="/var/lib/bind/db.${NS_DOMAIN}"
NS_ADDR_COUNT=${NS_ADDR_COUNT:-1}

# NS1_ADDR=192.168.0.151
# NS2_ADDR=192.168.0.152
# NS3_ADDR=192.168.0.153

# Generate NS_DOMAIN zone
cat <<EOF > "${NS_DATABASE}"
\$ORIGIN ${NS_DOMAIN}.
\$TTL 1800
${NS_DOMAIN}. IN SOA ns1.${NS_DOMAIN}. hostmaster.${NS_DOMAIN}. 1674985166 10800 3600 604800 1800
${NS_DOMAIN}. 1800 IN NS ns1.${NS_DOMAIN}.
EOF

# Add NS record to NS_DOMAIN zone
for((i=1;i<="${NS_ADDR_COUNT}";i++)); do
    record="NS${i}_ADDR"
    record="${!record}"
    echo "ns${i}     1800    IN  A   ${record}" >> "${NS_DATABASE}"
done

cat <<EOF >> "${NAMED_CONF_FILE}"

// Default name server zone ${NS_DOMAIN}
zone "${NS_DOMAIN}." {
  type ${NS_ROLE};
  file "${NS_DATABASE}";
  notify explicit;
};
EOF

# Debug print
if [[ -z "${DEBUG}" ]]; then

    echo ""
    echo "Inspecting ${NS_DATABASE}:"
    cat "${NS_DATABASE}"
    echo "============================================================="
fi

# ---

AVAILABLE_ZONES="${AVAILABLE_ZONES}"
IFS=', ' read -r -a _AVAILABLE_ZONES <<< "${AVAILABLE_ZONES}"

cat <<EOF >> "${NAMED_CONF_FILE}"
//
// Add you zones here
//

EOF

# Loop over AVAILABLE_ZONES list
# Generate stub zone file for each domain
# Add zone to NAMED_CONF_FILE
for zone in "${_AVAILABLE_ZONES[@]}"
do

    ZONE_DATABASE="/var/lib/bind/db.${zone}"

# cat <<EOF > "${ZONE_DATABASE}"
cat <<EOF > "${ZONE_DATABASE}"
\$ORIGIN .
\$TTL 1800	; 30 minutes
${zone}	IN SOA	ns1.${NS_DOMAIN}. hostmaster.${zone}. (
				1674985167 ; serial
				10800      ; refresh (3 hours)
				3600       ; retry (1 hour)
				604800     ; expire (1 week)
				1800       ; minimum (30 minutes)
				)
EOF
# cat <<EOF > "${ZONE_DATABASE}"

    # Add NS record to zone
    for((i=1;i<="${NS_ADDR_COUNT}";i++)); do
        echo "			NS ns${i}.${NS_DOMAIN}." >> "${ZONE_DATABASE}"
    done

    # Debug print
    if [[ -z "${DEBUG}" ]]; then
        echo ""
        echo "Inspecting ${ZONE_DATABASE}:"
        cat "${ZONE_DATABASE}"
        echo "============================================================="
    fi

# Add zone to NAMED_CONF_FILE as primary
# Setup allow-transfer for OCTODNS_KEY_NAME and NS${i}_ADDR
if [[ "${NS_ROLE}" == "primary" ]]; then
cat <<EOF >> "${NAMED_CONF_FILE}"
// ${zone}
zone "${zone}." {
  type ${NS_ROLE};
  file "${ZONE_DATABASE}";
  notify explicit;
  // IP addresses of secondary servers allowed to
  // transfer the zone
  allow-transfer {
    key "${OCTODNS_KEY_NAME}";
EOF
for((i=2;i<="${NS_ADDR_COUNT}";i++)); do
    record="NS${i}_ADDR"
    record="${!record}"
    echo "    ${record};" >> "${NAMED_CONF_FILE}"
done
cat <<EOF >> "${NAMED_CONF_FILE}"
  };
};

EOF
# Add zone to NAMED_CONF_FILE as secondary
# Setup masters to NS1_ADDR
elif [[ "${NS_ROLE}" == "secondary" ]]; then
cat <<EOF >> "${NAMED_CONF_FILE}"
// ${zone}
zone "${zone}." {
  type ${NS_ROLE};
  file "${ZONE_DATABASE}";
  notify explicit;
  // IP address of eng.example.com primary server
  masters { ${NS1_ADDR}; };
};

EOF
fi


done # for zone in "${_AVAILABLE_ZONES[@]}"

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
