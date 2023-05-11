#!/usr/bin/bash
set -e

# Nameserver
NS_SERVER_DOMAIN="${NS_SERVER_DOMAIN:-nameserver.corpnet}"
NS_SERVER_ROLE=${NS_SERVER_ROLE:-primary} # role: primary or secondary
NS_DATABASE="/var/lib/bind/db.nameserver"

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

# Generate NS_SERVER_DOMAIN zone
cat <<EOF > "${NS_DATABASE}"
\$ORIGIN ${NS_SERVER_DOMAIN}.
\$TTL 1800			; 30 minutes
${NS_SERVER_DOMAIN}. IN SOA ${ZONE_MNAME}. ${ZONE_RNAME}. (
							1       ; serial
							${ZONE_REFRESH}      ; refresh (3 hours)
							${ZONE_RETRY}      ; retry (1 hour)
							${ZONE_EXPIRE}      ; expire (1 week)
							${ZONE_TTL}     ; minimum (30 minutes)
							)
EOF

NAMESERVERS="${NAMESERVERS}"
IFS=', ' read -r -a _NAMESERVERS <<< "${NAMESERVERS}"

# Add NS record to NS_SERVER_DOMAIN zone
for((i=1;i<="${#_NAMESERVERS[@]}";i++)); do
    echo "${NS_SERVER_DOMAIN}.		1800	IN	NS	ns${i}.${NS_SERVER_DOMAIN}." >> "${NS_DATABASE}"
done

# Add A record for each NS to NS_SERVER_DOMAIN zone
_index=1
for _NAMESERVER in "${_NAMESERVERS[@]}"
do
    echo "ns${_index}				1800	IN	A	${_NAMESERVER}" >> "${NS_DATABASE}"
    ((_index=_index+1))
done
unset _index

fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
