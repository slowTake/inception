#!/bin/sh
# Quick health check for evaluation hosts.
set -e

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

ok() { printf "${GREEN}OK${RESET}  %s\n" "$1"; }
fail() { printf "${RED}FAIL${RESET} %s\n" "$1"; FAIL=1; }
warn() { printf "${YELLOW}WARN${RESET} %s\n" "$1"; }

FAIL=0

echo "==> Docker containers"
for c in mariadb wordpress nginx; do
	if docker ps --format '{{.Names}}' | grep -qx "$c"; then
		ok "container $c running"
	else
		fail "container $c not running"
	fi
done

echo "==> PID 1 (no bash/sleep hacks)"
for c in mariadb wordpress nginx; do
	if docker ps --format '{{.Names}}' | grep -qx "$c"; then
		pid1=$(docker exec "$c" ps -o comm= -p 1 2>/dev/null || true)
		case "$pid1" in
			bash|sh|sleep|tail) fail "$c PID1 is $pid1" ;;
			*) ok "$c PID1 is $pid1" ;;
		esac
	fi
done

echo "==> Volumes"
for v in mariadb wordpress; do
	if docker volume ls --format '{{.Name}}' | grep -qx "$v"; then
		ok "volume $v exists"
	else
		fail "volume $v missing"
	fi
done

echo "==> Network"
if docker network ls --format '{{.Name}}' | grep -qx docker-network; then
	ok "docker-network exists"
else
	fail "docker-network missing"
fi

echo "==> HTTPS entrypoint"
if curl -sk --connect-timeout 5 https://127.0.0.1/ -o /dev/null -w '' 2>/dev/null; then
	ok "port 443 responds"
else
	warn "port 443 not reachable (is /etc/hosts set?)"
fi

if [ "$FAIL" -ne 0 ]; then
	exit 1
fi
