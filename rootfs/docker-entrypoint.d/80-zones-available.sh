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
${ZONE}	IN SOA	ns.${NS_SERVER_DOMAIN}. hostmaster.${ZONE}. (
				1       ; serial
				${ZONE_REFRESH}      ; refresh (3 hours)
				${ZONE_RETRY}      ; retry (1 hour)
				${ZONE_EXPIRE}      ; expire (1 week)
				${ZONE_TTL}     ; minimum (30 minutes)
				)
EOF
# cat <<EOF > "${ZONE_DATABASE}"

ZONES_NAMESERVERS="${ZONES_NAMESERVERS}"
IFS=', ' read -r -a _ZONES_NAMESERVERS <<< "${ZONES_NAMESERVERS}"

# Add NS record to zone
for((i=1;i<="${#_ZONES_NAMESERVERS[@]}";i++)); do
	echo "			NS ns${i}.${NS_SERVER_DOMAIN}." >> "${ZONE_DATABASE}"
done

fi # if [ ! -f "${ZONE_DATABASE}" ]; then
fi # if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then

echo " - ${ZONE} => ${ZONE_DATABASE}"

done # for zone in "${_ZONES_AVAILABLE[@]}"
