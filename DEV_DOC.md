# Developer documentation — Inception

How to set up, build, and maintain the Inception Docker stack from scratch.

## Prerequisites

| Tool | Version / notes |
|------|-----------------|
| OS | Alpine Linux 3.20.x in a VM |
| Docker | From `apk add docker` |
| Docker Compose | `docker-cli-compose` plugin |
| Make | `apk add make` |
| Git | optional, for version control |

Hardware: **2 GB RAM**, **1 CPU**, **20+ GB** disk (see [setup.md](setup.md)).

## Repository layout

```text
.
├── Makefile                 # Entry point: build & run
├── scripts/
│   ├── configure-env.sh     # Generate .env + secrets
│   ├── setup-hosts.sh       # /etc/hosts helper
│   ├── check-services.sh    # Evaluation health script
│   └── vm-setup-docker.sh   # Alpine Docker install
├── secrets/                 # Git-ignored credential files
└── srcs/
    ├── docker-compose.yml
    ├── .env                 # Git-ignored (from configure-env.sh)
    ├── .env.example
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

## First-time setup

```sh
git clone <repo> inception && cd inception

# Generate secrets and .env
./scripts/configure-env.sh <login>

# Hostname resolution
sudo ./scripts/setup-hosts.sh <login>

# Install Docker (inside Alpine VM, once)
sudo ./scripts/vm-setup-docker.sh <login>
# log out & back in

# Build and run
make LOGIN=<login>
```

### Configuration files

| File | Role |
|------|------|
| `srcs/.env` | `DOMAIN_NAME`, DB names, WordPress users, passwords, `DATA_PATH` |
| `srcs/docker-compose.yml` | Services, volumes, network, healthchecks |
| `Makefile` | `LOGIN`, `DATA_DIR`, orchestrates compose |

`DATA_PATH` in `.env` must match bind mount paths in `docker-compose.yml` (`/home/<login>/data`).

## Build and launch

```sh
make LOGIN=<login>           # data dirs + build + up
make LOGIN=<login> images    # build only
make LOGIN=<login> up        # start only
make LOGIN=<login> logs      # follow logs
make LOGIN=<login> ps        # container status
```

Foreground rebuild (debug):

```sh
cd srcs && docker compose up --build
```

## Managing containers & volumes

```sh
make down                      # stop stack
make clean                     # stop + remove images & named volumes
make fclean                    # clean + rm -rf /home/<login>/data
make re                        # fclean + full rebuild
```

Inspect resources:

```sh
docker volume ls
docker volume inspect mariadb
docker volume inspect wordpress
docker network inspect docker-network
docker exec -it mariadb ps -p 1 -o comm=
```

## Where data persists

| Host path | Container mount | Content |
|-----------|-----------------|---------|
| `/home/<login>/data/mariadb` | `/var/lib/mysql` | MariaDB database files |
| `/home/<login>/data/wordpress` | `/var/www/html` | WordPress core, uploads, plugins |

Data survives `make down`. It is removed only by `make fclean` or manual `rm -rf`.

## Service internals

### MariaDB

- **Image:** `mariadb:inception`
- **PID 1:** `mysqld`
- **Init:** `tools/mariadb-script.sh` — first-run bootstrap only
- **Config:** `conf/mariadb_config` — 64M buffer pool for low RAM

### WordPress

- **Image:** `wordpress:inception`
- **PID 1:** `php-fpm83`
- **Init:** `tools/wordpress-script.sh` — WP-CLI download & install
- **Listens:** TCP 9000 (internal)

### NGINX

- **Image:** `nginx:inception`
- **PID 1:** `nginx`
- **Init:** `tools/nginx-entrypoint.sh` — self-signed TLS cert from `$DOMAIN_NAME`
- **Publishes:** 443 → host

## Subject compliance checklist

- [x] Custom Dockerfiles per service (Alpine 3.20.6)
- [x] No `latest` image tag
- [x] No passwords in Dockerfiles
- [x] `.env` for variables
- [x] Bind mounts under `/home/<login>/data`
- [x] Bridge network `docker-network` (no `host` / `links`)
- [x] `restart: always`
- [x] No `tail -f` / `sleep infinity` as PID 1
- [x] NGINX sole entry on 443, TLS 1.2/1.3
- [x] Two WordPress users; admin name avoids "admin"

## Low-resource tuning (Hive hardware)

| Setting | Location | Value |
|---------|----------|-------|
| Serial builds | `Makefile` | `COMPOSE_PARALLEL_LIMIT=1` |
| BuildKit off | `Makefile` | `DOCKER_BUILDKIT=0` |
| MariaDB buffer | `mariadb_config` | 64M |
| PHP-FPM children | `www.conf` | max 5 |
| NGINX workers | `nginx.conf` | 1 process, 256 connections |
| Healthcheck interval | `docker-compose.yml` | 15s |

## Editing after changes

After Dockerfile or compose changes:

```sh
make LOGIN=<login> images
make LOGIN=<login> up
```

After `.env` changes (non-secret): `make down && make up`.

If database credentials change: `make fclean` and reconfigure (wipes data).
