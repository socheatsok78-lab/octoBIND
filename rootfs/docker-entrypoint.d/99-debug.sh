#!/usr/bin/bash
set -e

if [[ -z "${DEBUG}" ]]; then
    exit 0
fi

print_file_debug() {
echo "// ==================== Debugging \"$1\" ===================="
cat "$1"
echo "// ==================== END!!!    \"$1\" ===================="
echo ""
}

print_file_debug "/etc/bind/named.conf.options"
print_file_debug "/etc/bind/named.conf.local"

if [[ "${NS_SERVER_ROLE}" == "primary" ]]; then
    if [[ -n "${ZONES_AVAILABLE}" ]]; then
        for col in /var/lib/bind/db.*; do
            if [[ "${col}" != *".jnl" ]]; then
                print_file_debug "$col"
            fi
        done
    fi

    if [[ -n "${ARPA_AVAILABLE}" ]]; then
        for col in /var/lib/bind/*.rev; do
            if [[ "${col}" != *".jnl" ]]; then
                print_file_debug "$col"
            fi
        done
    fi
fi
