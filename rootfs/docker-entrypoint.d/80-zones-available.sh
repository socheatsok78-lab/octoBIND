#!/usr/bin/bash
set -e

ZONES_AVAILABLE="${ZONES_AVAILABLE}"
IFS=', ' read -r -a _ZONES_AVAILABLE <<< "${ZONES_AVAILABLE}"

# Loop over ZONES_AVAILABLE list
# Generate stub zone file for each domain
# Add zone to NAMED_CONF_FILE
for ZONE in "${_ZONES_AVAILABLE[@]}"
do

ZONE_DATABASE="/var/lib/bind/db.${ZONE}"

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
# Do not override existing zone file
# Existing zone file might contain updated records
if [ ! -f "${ZONE_DATABASE}" ]; then
# cat <<EOF > "${ZONE_DATABASE}"
cat <<EOF > "${ZONE_DATABASE}"
\$ORIGIN .
\$TTL 1800	; 30 minutes
${ZONE}	IN SOA	ns1.${NS_SERVER_DOMAIN}. hostmaster.${ZONE}. (
				1       ; serial
				3h      ; refresh (3 hours)
				1h      ; retry (1 hour)
				1w      ; expire (1 week)
				30m     ; minimum (30 minutes)
				)
EOF
# cat <<EOF > "${ZONE_DATABASE}"

NS_SECONDARIES_ADDR="${NS_SECONDARIES_ADDR}"
IFS=', ' read -r -a _NS_SECONDARIES_ADDR <<< "${NS_SECONDARIES_ADDR}"

# Add NS record to zone
for((i=1;i<="${#_NS_SECONDARIES_ADDR[@]}";i++)); do
	echo "			NS ns${i}.${NS_SERVER_DOMAIN}." >> "${ZONE_DATABASE}"
done

fi # if [ ! -f "${ZONE_DATABASE}" ]; then
fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

echo " - ${ZONE} => ${ZONE_DATABASE}"

done # for zone in "${_ZONES_AVAILABLE[@]}"
