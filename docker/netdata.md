# 📖 Tutorial: Running Netdata with Docker via Portainer

## 🔹 1. Prerequisites

* Raspberry Pi or Linux host
* Docker and Portainer installed and running
* Optional: access to external disks or other services you want to monitor

---

## 🔹 2. Create Portainer Stack for Netdata

1. Go to **Portainer → Stacks → Add Stack**
2. Give it a name, e.g., `netdata`
3. Paste the following YAML:

```yaml
version: "3.8"
services:
  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    hostname: netdata
    ports:
      - 19999:19999      # Web UI port
    cap_add:
      - SYS_PTRACE        # needed for full system metrics
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    volumes:
      - netdata_config:/etc/netdata
      - netdata_lib:/var/lib/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro  # monitor Docker
    restart: unless-stopped

volumes:
  netdata_config:
  netdata_lib:
```

---

## 🔹 3. What this does

* Maps **host system info** (`/proc`, `/sys`, `/etc`) so Netdata can read metrics
* Mounts **Docker socket** to monitor containers
* Stores **Netdata config and db** in Docker volumes (`netdata_config` & `netdata_lib`) for persistence
* Exposes port **19999** → access the web dashboard at `http://<host-ip>:19999`

---

## 🔹 4. Deploy the Stack

* Click **Deploy the stack**
* Wait a few seconds for the container to start

---

## 🔹 5. Access the Netdata Web UI

* Open your browser:

```
http://<raspberry-pi-ip>:19999
```

* You’ll see a **real-time dashboard** with CPU, RAM, disks, network, and Docker container stats

---

## 🔹 6. Optional: Monitor Additional Disks or Paths

If you have external drives (e.g., `/media/data`) you want to track:

1. Mount the drive inside Netdata container (edit stack YAML):

```yaml
- /media/data:/host/media/data:ro
```

2. Netdata will automatically include disk usage metrics for `/host/media/data`.

---

## 🔹 7. Persistence & Updates

* Config and DB are stored in Docker volumes → safe if you redeploy or update the container
* To update Netdata, simply pull the latest image and recreate the stack:

```bash
docker pull netdata/netdata:latest
docker-compose up -d
```

(Portainer handles this if you redeploy the stack with the new image)

---

### ✅ Summary

* Netdata container runs fully in Docker
* Exposes port **19999**
* Monitors host system + Docker containers
* Uses Docker volumes for persistent configuration and database
* Can monitor external drives if mounted

---
