# Inception — Full setup guide

> **Short version:** [QUICKSTART.md](QUICKSTART.md) — campus cheat sheet with copy-paste commands.

Step-by-step instructions from an empty machine to a running WordPress site behind NGINX and MariaDB. Written for **Hive campus** evaluation on **older hardware** (2 GB RAM, single CPU).

Replace `pnurmi` with your 42/Hive login everywhere.

---

## Table of contents

1. [Overview](#1-overview)
2. [Hardware & VM sizing](#2-hardware--vm-sizing)
3. [Create the virtual machine](#3-create-the-virtual-machine)
4. [Install Alpine Linux](#4-install-alpine-linux)
5. [Post-install system setup](#5-post-install-system-setup)
6. [SSH (port 4241)](#6-ssh-port-4241)
7. [Install Docker](#7-install-docker)
8. [Get the project](#8-get-the-project)
9. [Configure environment & secrets](#9-configure-environment--secrets)
10. [Domain & hosts file](#10-domain--hosts-file)
11. [MariaDB service](#11-mariadb-service)
12. [WordPress service](#12-wordpress-service)
13. [NGINX service](#13-nginx-service)
14. [Build and launch](#14-build-and-launch)
15. [Verify the stack](#15-verify-the-stack)
16. [Evaluation cheat sheet](#16-evaluation-cheat-sheet)
17. [Troubleshooting on slow hosts](#17-troubleshooting-on-slow-hosts)

---

## 1. Overview

```
Browser ──HTTPS:443──► [ nginx ] ──FastCGI:9000──► [ wordpress + php-fpm ]
                                                          │
                                                          ▼
                                                    [ mariadb:3306 ]

Volumes (bind mounts on host):
  /home/<login>/data/mariadb    → MariaDB data
  /home/<login>/data/wordpress  → WordPress files
```

Startup order: **mariadb** → **wordpress** → **nginx** (enforced by healthchecks).

---

## 2. Hardware & VM sizing

Hive eval machines are often old. Use these minimums:

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM      | 2048 MB | 2048 MB (do not exceed host capacity) |
| CPUs     | 1       | 1           |
| Disk     | 20 GB   | 30 GB       |
| Swap     | 512 MB  | 1 GB (Alpine: enable if builds OOM) |

**Tips for slow hardware:**

- Store the VM disk on **local SSD**, not network storage (`goinfre` fills up — use USB or local disk if possible).
- Close the VM graphical desktop during `make` (use SSH only).
- This repo sets `COMPOSE_PARALLEL_LIMIT=1` and small MariaDB/PHP-FPM pools to reduce memory spikes.

---

## 3. Create the virtual machine

### 3.1 Install VirtualBox

Download from [virtualbox.org](https://www.virtualbox.org/).

### 3.2 Download Alpine ISO

Penultimate stable Alpine (subject requirement):

```text
https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.6-x86_64.iso
```

Use the **virt** image (no desktop bundled — lighter).

### 3.3 New VM in VirtualBox

1. **New** → Name: `Inception`
2. **Type:** Linux → **Other Linux (64-bit)**
3. **Memory:** 2048 MB
4. **Processors:** 1 CPU
5. **Disk:** 30 GB, dynamically allocated
6. **Storage:** attach the Alpine ISO as optical drive
7. **Network:** NAT (default); we add SSH port forwarding later

Start the VM once to confirm the ISO boots, then continue with installation.

---

## 4. Install Alpine Linux

At the `localhost login:` prompt, log in as **root** (no password on live ISO).

```sh
setup-alpine
```

| Prompt | Value |
|--------|-------|
| Keyboard | `us` / `us` |
| Hostname | `pnurmi.42.fr` |
| Interface | default, DHCP (`n` for manual) |
| Root password | choose and remember |
| Timezone | `Europe/Helsinki` (or your zone) |
| Proxy | `none` |
| SSH | `openssh` |
| NTP | `chrony` |
| Disk | `sda` → `sys` → confirm `y` |

When finished:

1. VirtualBox → **Settings → Storage** → remove the ISO from the optical drive
2. In the VM: `reboot`

Log in as **root** after reboot.

---

## 5. Post-install system setup

### 5.1 Create your user

```sh
adduser -g "Pnurmi User" pnurmi
adduser pnurmi wheel
apk add sudo
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
```

### 5.2 Enable community repo (needed for Docker)

```sh
vi /etc/apk/repositories
# Uncomment the line ending in /community
apk update && apk upgrade
```

### 5.3 Basic packages

```sh
apk add git make curl nano openssh
```

### 5.4 (Optional) Lightweight desktop

Only if you want a GUI browser inside the VM:

```sh
apk add xfce4 xfce4-terminal lightdm lightdm-gtk-gtk-greeter
rc-update add lightdm
```

For evaluation, **SSH + Firefox on host** or `curl` tests are enough.

---

## 6. SSH (port 4241)

Hive expects SSH on **4241**, not 22.

```sh
# As root
sed -i 's/#Port 22/Port 4241/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
rc-service sshd restart
```

**VirtualBox port forwarding:**

1. VM **Settings → Network → Advanced → Port Forwarding**
2. Add rule: Host `4241` → Guest `4241`

From your **host** terminal:

```sh
ssh -p 4241 pnurmi@127.0.0.1
```

Do the rest of the setup over SSH — it is faster than the VM console.

---

## 7. Install Docker

Inside the VM (as root or with sudo):

```sh
cd /path/to/inception   # after clone; or run script from repo
sudo ./scripts/vm-setup-docker.sh pnurmi
```

Or manually:

```sh
apk add docker docker-cli-compose openrc make
rc-update add docker boot
service docker start
adduser pnurmi docker
```

**Log out and back in** so the `docker` group applies.

Verify:

```sh
docker --version
docker compose version
docker run --rm alpine:3.20.6 echo ok
```

---

## 8. Get the project

```sh
cd ~
git clone <your-repo-url> inception
cd inception
```

Expected layout:

```text
inception/
├── Makefile
├── README.md
├── setup.md
├── USER_DOC.md
├── DEV_DOC.md
├── scripts/
├── secrets/
└── srcs/
    ├── docker-compose.yml
    ├── .env.example
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

---

## 9. Configure environment & secrets

Never commit real passwords. Generate local files:

```sh
./scripts/configure-env.sh pnurmi
```

This creates:

- `srcs/.env` — variables for Compose and container scripts
- `secrets/credentials.txt` — human-readable summary for evaluation
- `secrets/db_password.txt`, `secrets/db_root_password.txt`

Edit `srcs/.env` if you need to change the WordPress title or emails.

**Subject rules:**

- Admin username must **not** contain `admin` or `administrator` (default: `pnurmi_boss`).
- Two WordPress users: administrator + regular user.
- No passwords in Dockerfiles.

Update the Makefile default login if needed:

```makefile
LOGIN ?= pnurmi
```

---

## 10. Domain & hosts file

The site URL is `https://pnurmi.42.fr`. Point it to the VM loopback:

```sh
sudo ./scripts/setup-hosts.sh pnurmi
```

Check:

```sh
grep pnurmi.42.fr /etc/hosts
# 127.0.0.1   pnurmi.42.fr
```

---

## 11. MariaDB service

**Location:** `srcs/requirements/mariadb/`

| File | Purpose |
|------|---------|
| `Dockerfile` | Alpine + MariaDB packages |
| `conf/mariadb_config` | `mysqld` settings (low memory) |
| `tools/mariadb-script.sh` | Init DB, create users, `exec mysqld` |

**What happens on first start:**

1. `mariadb-install-db` creates system tables in `/var/lib/mysql` (bind-mounted to `/home/pnurmi/data/mariadb`).
2. SQL bootstrap sets root password, creates `wordpress_db`, creates `wp_db_user`.
3. `mysqld` runs as PID 1 (no shell loops).

**Manual checks after `make`:**

```sh
docker logs mariadb
docker exec -it mariadb sh
mariadb -u wp_db_user -p -e "SHOW DATABASES;"
```

---

## 12. WordPress service

**Location:** `srcs/requirements/wordpress/`

| File | Purpose |
|------|---------|
| `Dockerfile` | PHP 8.3-FPM + extensions |
| `conf/www.conf` | PHP-FPM pool (5 workers max) |
| `tools/wordpress-script.sh` | WP-CLI install, `exec php-fpm83 -F` |

**What happens on first start:**

1. Waits for MariaDB (`mariadb-admin ping`).
2. Downloads WordPress via WP-CLI.
3. Creates `wp-config.php` and runs `wp core install`.
4. Creates secondary user from `.env`.
5. PHP-FPM listens on **9000** inside the network.

**Manual checks:**

```sh
docker logs wordpress
docker exec -it wordpress ps aux | grep php-fpm
docker exec -it wordpress wp user list --allow-root --path=/var/www/html
```

---

## 13. NGINX service

**Location:** `srcs/requirements/nginx/`

| File | Purpose |
|------|---------|
| `Dockerfile` | Alpine + nginx + openssl |
| `conf/nginx.conf` | HTTP→HTTPS redirect, TLS 1.2/1.3, FastCGI |
| `tools/nginx-entrypoint.sh` | Generate cert for `$DOMAIN_NAME`, start nginx |

**Rules satisfied:**

- Only **443** published to the host.
- TLS **1.2** and **1.3** only.
- PHP passed to `wordpress:9000`.
- `nginx -g 'daemon off;'` as PID 1.

**Manual checks:**

```sh
docker exec -it nginx sh -c "netstat -tlnp | grep 443"
curl -vk https://pnurmi.42.fr/
```

---

## 14. Build and launch

```sh
cd ~/inception
make LOGIN=pnurmi
```

First build on old hardware can take **10–20 minutes**. Subsequent starts are faster.

Individual steps:

```sh
make LOGIN=pnurmi data-dirs   # /home/pnurmi/data/{mariadb,wordpress}
make LOGIN=pnurmi images      # build mariadb, wordpress, nginx
make LOGIN=pnurmi up            # start detached
```

Foreground debug (see all logs):

```sh
cd srcs
docker compose up --build
```

---

## 15. Verify the stack

```sh
make status
docker ps
```

| Check | Command |
|-------|---------|
| Containers up | `docker ps` → mariadb, wordpress, nginx |
| PID 1 not a hack | `docker exec mariadb ps -p 1 -o comm=` → `mysqld` |
| Volumes | `docker volume inspect mariadb` → device `/home/pnurmi/data/mariadb` |
| Network | `docker network inspect docker-network` |
| HTTPS | Browser → `https://pnurmi.42.fr` |
| WP admin | `https://pnurmi.42.fr/wp-admin` |

Credentials: `cat secrets/credentials.txt`

---

## 16. Evaluation cheat sheet

### Transfer project to eval VM

```sh
scp -P 4241 -r ./inception pnurmi@127.0.0.1:~/
```

### Nuclear Docker reset

```sh
docker stop $(docker ps -qa) 2>/dev/null
docker rm $(docker ps -qa) 2>/dev/null
docker rmi -f $(docker images -qa) 2>/dev/null
docker volume rm $(docker volume ls -q) 2>/dev/null
docker network prune -f
```

### MariaDB

```sh
docker exec -it mariadb mariadb -u root -p
SHOW DATABASES;
USE wordpress_db;
SHOW TABLES;
SELECT user_login FROM wp_users;
```

### WordPress → DB connectivity

```sh
docker exec -it wordpress sh
mariadb -h mariadb -u wp_db_user -p wordpress_db -e "SELECT 1;"
```

### NGINX / TLS

```sh
docker exec -it nginx sh
wget -qO- --no-check-certificate https://127.0.0.1/ | head
```

### Stop / start for evaluator

```sh
make down
make LOGIN=pnurmi
```

---

## 17. Troubleshooting on slow hosts

| Symptom | Fix |
|---------|-----|
| `docker build` killed / OOM | Add swap: `fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile` |
| Build hangs forever | `export DOCKER_BUILDKIT=0` (already in Makefile) |
| WordPress healthcheck fails | Wait longer; first WP-CLI download is slow — `docker logs -f wordpress` |
| `502 Bad Gateway` | WordPress not ready: `docker logs wordpress`, check php-fpm |
| Certificate warning in browser | Expected — self-signed cert; continue for eval |
| `permission denied` on data dir | `sudo chown -R pnurmi:pnurmi /home/pnurmi/data` |
| Port 443 in use | `sudo netstat -tlnp \| grep 443` — stop conflicting service |

---

## Reference

- Subject: [en.subject.pdf](en.subject.pdf)
- Campus example: [github.com/TanjaMenkovic/inception](https://github.com/TanjaMenkovic/inception)
- Developer details: [DEV_DOC.md](DEV_DOC.md)
- End-user guide: [USER_DOC.md](USER_DOC.md)
