#!/usr/bin/bash
set -e

if [[ -z "${DEBUG}" ]]; then
    exit 0
fi

print_file_debug() {
echo "//
// Showing \"$1\"
//"
cat "$1"
echo ""
}

print_file_debug "/etc/bind/named.conf.options"
print_file_debug "/etc/bind/named.conf.local"

for col in /var/lib/bind/db.*; do
    if [[ "${col}" != *".jnl" ]]; then
        print_file_debug "$col"
    fi
done
