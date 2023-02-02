#!/usr/bin/bash
set -e

if [[ -n "${DEBUG}" ]]; then
    echo "=================================================="
    echo "Showing ${OCTODNS_KEY_FILE}:"
    echo "=================================================="
    cat "${OCTODNS_KEY_FILE}"
    echo ""

    echo "=================================================="
    echo "Showing ${NAMED_OPTIONS_FILE}:"
    echo "=================================================="
    cat "${NAMED_OPTIONS_FILE}"
    echo ""

    echo "=================================================="
    echo "Showing ${NAMED_CONF_FILE}:"
    echo "=================================================="
    cat "${NAMED_CONF_FILE}"

    echo "=================================================="
    echo "Showing zone files:"
    echo "=================================================="
    for col in $(ls "/var/lib/bind"); do
        echo "$col:"
        echo "|"
        cat "/var/lib/bind/$col"
        echo ""
    done
fi
