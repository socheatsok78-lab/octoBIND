#!/usr/bin/bash
set -e

NAMED_OPTIONS_FILE="${NAMED_OPTIONS_FILE:-/etc/bind/named.conf.options}"
NAMED_OPTIONS_BACKUP_FILE="${NAMED_OPTIONS_FILE}.origin"

# Create backup for NAMED_OPTIONS_FILE
if [ ! -f "${NAMED_OPTIONS_BACKUP_FILE}" ]; then
	cp "${NAMED_OPTIONS_FILE}" "${NAMED_OPTIONS_BACKUP_FILE}"
fi

# Generate "forwarders {};" block
NS_FORWARDER_IPS=""
NS_FORWARDERS="${NS_FORWARDERS}"
IFS=', ' read -r -a _NS_FORWARDERS <<< "${NS_FORWARDERS}"
for forwarder in "${_NS_FORWARDERS[@]}"
do
	NS_FORWARDER_IPS="${NS_FORWARDER_IPS}${forwarder}; "
done

# Generate NS_FORWARDER_OPTIONS
NS_FORWARDER_OPTIONS=""
if [[ -n "${NS_FORWARDER_IPS}" ]]; then
	NS_FORWARDER_OPTIONS="
	recursion yes;
	allow-query { any; };
	allow-recursion { corpnets; };
	forwarders { ${NS_FORWARDER_IPS}};
	"
else
	NS_FORWARDER_OPTIONS="
	// recursion yes;
	// allow-query { any; };
	// allow-recursion { corpnets; };
	// forwarders { 0.0.0.0 };
	"
fi

# Primary nameservers
NS_PRIMARY_IPS=""
if [[ -n "${NS_SERVER_1_ADDR}" ]]; then
	NS_PRIMARY_IPS="${NS_SERVER_1_ADDR};"
fi

# Secondary nameservers
NS_SECONDARY_IPS=""
for((i=2;i<="${NS_SERVER_COUNT}";i++)); do
	record="NS_SERVER_${i}_ADDR"
	record="${!record}"

	NS_SECONDARY_IPS="${NS_SECONDARY_IPS}${record}; "
done

# Create a new NAMED_OPTIONS_FILE from NAMED_OPTIONS_BACKUP_FILE everytime the system boot
cat <<EOF > "${NAMED_OPTIONS_FILE}"
// Default ACL for corporation networks
// Matches any host on an IPv4 or IPv6 network for which the system has an interface.
acl acl-ns-primaries { ${NS_PRIMARY_IPS}};
acl acl-ns-secondaries { ${NS_SECONDARY_IPS}};
acl acl-corpnets { localhost; localnets; };

// A lists of primary servers
primaries ns-primaries { acl-ns-primaries key "${OCTODNS_KEY_NAME}";};

// Default nameserver options
options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable
	// nameservers, you probably want to use them as forwarders.
	// Uncomment the following block, and insert the addresses replacing
	// the all-0's placeholder.
	${NS_FORWARDER_OPTIONS}

	// Enable NOTIFY when zone changes occur
	notify yes;

	// Allow outgoing zone transfers
	allow-transfer  { key "${OCTODNS_KEY_NAME}"; }; # AXFR

	// Allow submit dynamic updates for primary zones
	allow-update    { key "${OCTODNS_KEY_NAME}"; }; # RFC 2136

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation auto;

	listen-on-v6 { any; };
};
EOF
