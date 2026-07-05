# Quick manual setup — campus cheat sheet

**Replace `LOGIN` with your Hive login everywhere** (example: `pnurmi`).

Full details: [setup.md](setup.md) · Eval prep: [USER_DOC.md](USER_DOC.md)

---

## A. Fresh VM (first time only)

### VirtualBox

| Setting | Value |
|---------|-------|
| OS | Alpine Linux 3.20.6 **virt** ISO |
| RAM | 2048 MB |
| CPU | 1 |
| Disk | 30 GB |
| SSH forward | host **4241** → guest **4241** |

ISO: `https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.6-x86_64.iso`

### Alpine install (`setup-alpine`)

```
Hostname     → LOGIN.42.fr
Root password → (remember it)
User         → LOGIN (+ wheel/sudo)
Timezone     → Europe/Helsinki
Disk         → sda → sys → y
```

After install: remove ISO from VirtualBox storage → `reboot`.

### SSH (port 4241)

```sh
# as root inside VM
sed -i 's/#Port 22/Port 4241/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
rc-service sshd restart
```

Connect from host: `ssh -p 4241 LOGIN@127.0.0.1`

### Docker (once per VM)

```sh
# enable community repo first
sudo vi /etc/apk/repositories   # uncomment line with /community
sudo apk update

cd ~/inception
sudo ./scripts/vm-setup-docker.sh LOGIN
```

**Log out and back in** — required for `docker` group.

---

## B. Project setup (copy-paste)

### 1. Get repo onto VM

From your laptop (if project is local):

```sh
scp -P 4241 -r ./inception LOGIN@127.0.0.1:~/
```

Or inside VM: `git clone <your-repo-url> inception`

### 2. Configure & build

```sh
ssh -p 4241 LOGIN@127.0.0.1
cd ~/inception

./scripts/configure-env.sh LOGIN
sudo ./scripts/setup-hosts.sh LOGIN

make LOGIN=LOGIN          # first run: 10–20 min on slow hardware
make status
cat secrets/credentials.txt   # save / memorize passwords
```

### 3. Test in browser

- Site: `https://LOGIN.42.fr`
- Admin: `https://LOGIN.42.fr/wp-admin`
- User: `LOGIN_boss` (admin — no "admin" in the name)

---

## C. Evaluation day (tomorrow)

```sh
ssh -p 4241 LOGIN@127.0.0.1
cd ~/inception

grep LOGIN.42.fr /etc/hosts || sudo ./scripts/setup-hosts.sh LOGIN

docker ps                  # expect: mariadb, wordpress, nginx
make LOGIN=LOGIN up          # if not running (skip build if images exist)
make status

curl -k -I https://LOGIN.42.fr
cat secrets/credentials.txt
```

**Evaluator may ask:**

```sh
make down
make LOGIN=LOGIN up
docker logs mariadb
docker logs wordpress
docker logs nginx
docker volume inspect mariadb
docker network inspect docker-network
docker exec -it mariadb mariadb -u wp_db_user -p -e "SHOW DATABASES;"
```

---

## D. Makefile reminder

Always pass your login if Makefile still says `pnurmi`:

```sh
make LOGIN=yourlogin
make LOGIN=yourlogin down
make LOGIN=yourlogin status
```

---

## E. If something breaks (slow campus hardware)

| Problem | Fix |
|---------|-----|
| Build killed / OOM | Add 1G swap, close VM desktop, use SSH only |
| `permission denied` on docker | Log out/in after `vm-setup-docker.sh` |
| `permission denied` on data | `sudo chown -R LOGIN:LOGIN /home/LOGIN/data` |
| Site not found | `sudo ./scripts/setup-hosts.sh LOGIN` |
| 502 / WP not ready | `docker logs -f wordpress` (wait for WP-CLI) |
| Nuclear reset | `make LOGIN=LOGIN fclean` then section B again |

---

## F. What evaluators check (mandatory only)

- [ ] 3 containers, correct names: `mariadb`, `wordpress`, `nginx`
- [ ] Only **443** open to host
- [ ] HTTPS works, TLS 1.2/1.3
- [ ] Data in `/home/LOGIN/data/mariadb` and `.../wordpress`
- [ ] Two WP users; admin name has no "admin"
- [ ] PID 1 is `mysqld` / `php-fpm83` / `nginx` (not bash/sleep)
- [ ] You can explain credentials without reading Git

No bonus services required.
