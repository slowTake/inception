#!/bin/sh
# Add login.42.fr to /etc/hosts pointing at loopback.
# Usage: sudo ./scripts/setup-hosts.sh <login>

set -e

LOGIN="${1:-pnurmi}"
DOMAIN="${LOGIN}.42.fr"
HOSTS_FILE="/etc/hosts"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run with sudo: sudo $0 ${LOGIN}"
	exit 1
fi

if grep -q "[[:space:]]${DOMAIN}$" "$HOSTS_FILE" 2>/dev/null; then
	echo "${DOMAIN} already present in ${HOSTS_FILE}"
	exit 0
fi

echo "127.0.0.1   ${DOMAIN}" >> "$HOSTS_FILE"
echo "Added ${DOMAIN} -> 127.0.0.1"
