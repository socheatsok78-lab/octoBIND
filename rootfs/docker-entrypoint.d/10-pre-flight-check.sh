#!/usr/bin/bash
set -e

check_env() {
    if [[ -z "${!1}" ]]; then
        echo "[ERR]: The ${1} environment variable is missing."
        return 1
    fi

    return
}

# Verify that NS_SERVER_COUNT value is set
check_env "NS_SERVER_COUNT"

# Verify that environment variables associated with NS_SERVER_COUNT are all set
for((i=1;i<="${NS_SERVER_COUNT}";i++)); do
	check_env "NS_SERVER_${i}_ADDR"
done
