# User documentation — Inception

Simple guide for anyone who needs to run or check the Inception WordPress stack.

## What this stack provides

| Service | What it does |
|---------|----------------|
| **NGINX** | Secure web entry (HTTPS on port 443) |
| **WordPress** | Website and admin panel |
| **MariaDB** | Database storing WordPress content |

Your site address: **`https://<login>.42.fr`** (example: `https://pnurmi.42.fr`).

## Start the project

```sh
cd ~/inception
make LOGIN=<your_login>
```

Wait until all three containers are running (`docker ps` shows mariadb, wordpress, nginx).

## Stop the project

```sh
cd ~/inception
make down
```

## Access the website

1. Ensure `/etc/hosts` contains: `127.0.0.1   <login>.42.fr`
2. Open a browser: **https://<login>.42.fr**

## Access the WordPress admin panel

- URL: **https://<login>.42.fr/wp-admin**
- Use the administrator account from your credentials file (not named "admin").

## Credentials

After setup, passwords are stored locally (not in Git):

| File | Contents |
|------|----------|
| `secrets/credentials.txt` | All login summaries |
| `srcs/.env` | Variables used by Docker (includes passwords) |

Generate or regenerate:

```sh
./scripts/configure-env.sh <login>
```

**WordPress users created automatically:**

1. **Administrator** — `<login>_boss` (no "admin" in the name)
2. **Regular user** — `<login>`

## Check that services are healthy

Quick script:

```sh
make status
```

Manual checks:

```sh
docker ps                                    # 3 containers, state "Up"
docker logs mariadb --tail 20
docker logs wordpress --tail 20
docker logs nginx --tail 20
curl -k -I https://<login>.42.fr             # HTTP/2 or HTTP/1.1 200/301
```

If something fails, see [setup.md — Troubleshooting](setup.md#17-troubleshooting-on-slow-hosts).

## Restart after a crash

Containers use `restart: always`. Docker should restart them automatically.

To force a clean restart:

```sh
make down
make LOGIN=<your_login>
```
