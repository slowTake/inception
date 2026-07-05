*This project has been created as part of the 42 curriculum by pnurmi.*

# Inception

A small Docker-based web stack that runs **NGINX** (HTTPS), **WordPress + PHP-FPM**, and **MariaDB** inside a personal virtual machine. The project follows the [Inception subject](en.subject.pdf) (v5.1) and is tuned for **Hive campus evaluation hardware** (low RAM, single CPU).

## Description

Inception virtualizes three cooperating services with Docker Compose:

| Service   | Role                                      | Exposed port |
|-----------|-------------------------------------------|--------------|
| `nginx`   | TLS termination, reverse proxy to PHP-FPM | **443** only |
| `wordpress` | WordPress + PHP-FPM 8.3                 | internal     |
| `mariadb` | MariaDB database                          | internal     |

Persistent data lives in bind mounts under `/home/<login>/data/` (`mariadb/` and `wordpress/`). All containers share a custom bridge network `docker-network`.

### Project description — Docker & design choices

**Docker in this project:** Each service is built from a custom Dockerfile on Alpine Linux 3.20.6 (penultimate stable). Images are named after their service (`mariadb:inception`, `wordpress:inception`, `nginx:inception`). No pre-built Hub images are pulled except the Alpine base. Credentials live in `srcs/.env` and `secrets/` (git-ignored).

**Main design choices:**

- **Alpine** over Debian — smaller images, faster builds on slow disks.
- **Single worker / reduced PHP-FPM pool** — lowers memory on 2 GB VMs.
- **Runtime SSL + nginx config** — domain from `.env` without rebuilding nginx.
- **Healthchecks with longer intervals** — less CPU churn during startup on old hosts.
- **Serial image builds** (`COMPOSE_PARALLEL_LIMIT=1`) — avoids OOM during `make`.

| Topic | Choice here | Why |
|-------|-------------|-----|
| **VM vs Docker** | VM hosts Docker; each service is a container | VM provides isolation for the whole project; containers share the host kernel and start in seconds with far less RAM than nested VMs. |
| **Secrets vs env vars** | Passwords in `secrets/*.txt` + mirrored in `.env` for Compose | Subject requires `.env`; secrets folder gives evaluators a single credential reference without committing passwords to Git. Docker Secrets (Swarm) are optional; plain `.env` is enough for this compose setup. |
| **Docker network vs host network** | Custom bridge `docker-network` | Services resolve each other by name (`mariadb`, `wordpress`); only nginx publishes 443. `network: host` is forbidden by the subject. |
| **Docker volumes vs bind mounts** | Bind mounts to `/home/<login>/data/` | Subject mandates host paths for persistence; bind mounts make DB and WordPress files visible on the VM for backup and evaluation. |

## Instructions

### Prerequisites

- VirtualBox (or compatible hypervisor)
- Alpine Linux 3.20.x VM with ≥ **2 GB RAM**, **1 CPU**, **20 GB** disk
- SSH on port **4241** (Hive convention)
- Docker + Docker Compose inside the VM

### Quick start (inside the VM)

**Campus tomorrow?** Use **[QUICKSTART.md](QUICKSTART.md)** — copy-paste checklist.

```bash
# 1. Clone repo and enter project root
cd ~/inception

# 2. Generate .env and secrets (replace pnurmi with your login)
./scripts/configure-env.sh pnurmi

# 3. Point domain to localhost
sudo ./scripts/setup-hosts.sh pnurmi

# 4. Build and start
make LOGIN=pnurmi

# 5. Verify
make status
```

Open **https://pnurmi.42.fr** (replace with your login). WordPress admin: `https://<login>.42.fr/wp-admin`.

### Makefile targets

| Target   | Action |
|----------|--------|
| `make`   | Create data dirs, build images, start stack |
| `make down` | Stop containers |
| `make logs` | Follow compose logs |
| `make ps` | List containers |
| `make status` | Run health script |
| `make clean` | Remove containers, images, compose volumes |
| `make fclean` | `clean` + delete `/home/<login>/data` |
| `make re` | Full reset and rebuild |
| `make env` | Regenerate `.env` / secrets |
| `make hosts` | Add `<login>.42.fr` to `/etc/hosts` |

Set `LOGIN=yourlogin` on every `make` invocation if it differs from the Makefile default.

### Full setup guide

- **[QUICKSTART.md](QUICKSTART.md)** — short campus / manual install cheat sheet
- **[setup.md](setup.md)** — complete step-by-step (VM → MariaDB → WordPress → NGINX)

### Additional documentation

- **[USER_DOC.md](USER_DOC.md)** — start/stop, URLs, credentials, health checks
- **[DEV_DOC.md](DEV_DOC.md)** — developer setup, file layout, Docker commands

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose specification](https://docs.docker.com/compose/compose-file/)
- [MariaDB Docker notes](https://mariadb.com/kb/en/mariadb-server-docker-official-image-environment-variables/)
- [WordPress with Docker](https://developer.wordpress.org/advanced-administration/server/docker/)
- [NGINX TLS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WP-CLI](https://wp-cli.org/)
- Campus reference: [TanjaMenkovic/inception](https://github.com/TanjaMenkovic/inception)
- Subject PDF: [en.subject.pdf](en.subject.pdf)

### AI usage

AI (Cursor) was used to:

- Scaffold Dockerfiles, compose file, and shell scripts from the subject and reference repo
- Draft README, setup.md, USER_DOC.md, and DEV_DOC.md
- Apply low-resource tuning for Hive evaluation hardware

All generated files were reviewed against the subject constraints (no `latest` tag, no `tail -f` PID 1 hacks, TLS 1.2/1.3 only, mandatory `.env`, bind mounts under `/home/<login>/data`).
