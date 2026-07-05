#!/bin/sh
# Install Docker on Alpine Linux inside the Inception VM.
# Run as root or with sudo inside the VM.

set -e

if [ "$(id -u)" -ne 0 ]; then
	echo "Run with sudo."
	exit 1
fi

LOGIN="${1:-pnurmi}"

echo "==> Enabling community repository (if commented)..."
sed -i 's/^#\(.*\/community\)/\1/' /etc/apk/repositories || true

apk update
apk upgrade

echo "==> Installing Docker and Compose..."
apk add docker docker-cli-compose openrc make curl

echo "==> Enabling Docker at boot..."
rc-update add docker boot 2>/dev/null || true
service docker start

echo "==> Adding ${LOGIN} to docker group..."
addgroup "${LOGIN}" docker 2>/dev/null || adduser "${LOGIN}" docker

echo "==> Docker version:"
docker --version
docker compose version

echo "Done. Log out and back in so group membership applies."
