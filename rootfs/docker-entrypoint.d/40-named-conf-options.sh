#!/usr/bin/bash
set -e

NAMED_OPTIONS_FILE="${NAMED_OPTIONS_FILE:-/etc/bind/named.conf.options}"
NAMED_OPTIONS_BACKUP_FILE="${NAMED_OPTIONS_FILE}.origin"

# Create backup for NAMED_OPTIONS_FILE
if [ ! -f "${NAMED_OPTIONS_BACKUP_FILE}" ]; then
	cp "${NAMED_OPTIONS_FILE}" "${NAMED_OPTIONS_BACKUP_FILE}"
fi

# Generate "forwarders {};" block
NS_FORWARDERS_BLOCK=""
NS_RECURSION_BLOCK=""
NS_ALLOW_QUERY_BLOCK=""

NS_FORWARDERS="${NS_FORWARDERS}"
IFS=', ' read -r -a _NS_FORWARDERS <<< "${NS_FORWARDERS}"
for forwarder in "${_NS_FORWARDERS[@]}"
do
    NS_FORWARDERS_BLOCK="${NS_FORWARDERS_BLOCK}${forwarder}; "
done
if [[ -n "${NS_FORWARDERS_BLOCK}" ]]; then
    NS_FORWARDERS_BLOCK="forwarders { ${NS_FORWARDERS_BLOCK}};"
    NS_RECURSION_BLOCK="recursion yes;"
    NS_ALLOW_QUERY_BLOCK="allow-query { any; };"
else
    NS_FORWARDERS_BLOCK="// forwarders { 0.0.0.0 };"
    NS_RECURSION_BLOCK="// recursion yes;"
    NS_ALLOW_QUERY_BLOCK="// allow-query { any; };"
fi

# Create a new NAMED_OPTIONS_FILE from NAMED_OPTIONS_BACKUP_FILE everytime the system boot
cat <<EOF > "${NAMED_OPTIONS_FILE}"
options {
    directory "/var/cache/bind";

    // If there is a firewall between you and nameservers you want
    // to talk to, you may need to fix the firewall to allow multiple
    // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

    // If your ISP provided one or more IP addresses for stable
    // nameservers, you probably want to use them as forwarders.
    // Uncomment the following block, and insert the addresses replacing
    // the all-0's placeholder.

    ${NS_FORWARDERS_BLOCK}
    ${NS_ALLOW_QUERY_BLOCK}
    ${NS_RECURSION_BLOCK}

    //========================================================================
    // If BIND logs error messages about the root key being expired,
    // you will need to update your keys.  See https://www.isc.org/bind-keys
    //========================================================================
    dnssec-validation auto;

    listen-on-v6 { any; };
};
EOF
