#!/usr/bin/bash
set -e

chown -R "bind:bind" \
          /etc/bind \
          /var/lib/bind
