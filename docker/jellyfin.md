# 📖 Tutorial: Running Jellyfin on Raspberry Pi with External Disk in Portainer

## 🔹 1. Prerequisites

* Raspberry Pi with Ubuntu Server installed
* External disk connected (in your case `/dev/sda1` mounted at `/media/data`)
* Docker + Portainer already running

---

## 🔹 2. Prepare Folders on the Host

We’ll keep Jellyfin’s configs and cache under `/media/data/jellyfin` (on the external disk).

Run these commands on your Pi:

```bash
sudo mkdir -p /media/data/jellyfin/config
sudo mkdir -p /media/data/jellyfin/cache
sudo mkdir -p /media/data/media   # optional: place for movies/shows
```

Make sure Jellyfin’s container user (UID=1000, GID=1000) has access:

```bash
sudo chown -R 1000:1000 /media/data/jellyfin
sudo chown -R 1000:1000 /media/data/media
```

---

## 🔹 3. Fix External Disk Permissions (NTFS)

Since your external disk is NTFS, Linux needs the correct mount options so Docker/Jellyfin can read/write.

1. Get the UUID:

   ```bash
   sudo blkid /dev/sda1
   ```

   Example:

   ```
   UUID=E240123C401217BD
   ```

2. Edit `/etc/fstab`:

   ```bash
   sudo nano /etc/fstab
   ```

   Add this line at the end (replace with your UUID):

   ```
   UUID=E240123C401217BD  /media/data  ntfs-3g  uid=1000,gid=1000,umask=0022  0  0
   ```

3. Remount or reboot:

   ```bash
   sudo mount -a
   ```

Now the disk will always mount with the correct user/group IDs at boot.

---

## 🔹 4. Create Portainer Stack for Jellyfin

Go to **Portainer → Stacks → Add Stack** and paste this:

```yaml
version: "3.8"
services:
  jellyfin:
    image: linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Lisbon
    volumes:
      - /media/data/jellyfin/config:/config
      - /media/data/jellyfin/cache:/cache
      - /media/data:/external    # mount external disk
    ports:
      - 8096:8096
      - 8920:8920    # optional HTTPS
      - 7359:7359/udp
      - 1900:1900/udp
    restart: unless-stopped
```

Then click **Deploy the stack**.

---

## 🔹 5. Access Jellyfin Web UI

After a few seconds, open:

```
http://<raspberry-pi-ip>:8096
```

Set up your admin account.

---

## 🔹 6. Add Media Libraries

In the Jellyfin dashboard:

1. Go to **Dashboard → Libraries → Add Library**
2. Select type (Movies, TV Shows, Music, etc.)
3. For the folder path, use the path **inside the container**, e.g.:

   ```
   /external/Movies
   /external/TV
   /external/Music
   ```
4. Save and let Jellyfin scan your content.

---

## 🔹 7. Logs & Configs

* Configs, database, logs → `/media/data/jellyfin/config`
* Cache → `/media/data/jellyfin/cache`
* Your actual media → `/media/data/media` (or whatever structure you use under `/media/data`)

---

✅ Done!
Now Jellyfin is running via Portainer, configs are safe on your external disk, and the disk is mounted properly with the right permissions so you don’t hit *“The path could not be found”* anymore.

---

# 📖 Extended Tutorial: Backup & Restore Jellyfin on Raspberry Pi

### 🔹 1. What to Backup

To fully restore Jellyfin, you need to back up:

1. **Configs, database, logs** → `/media/data/jellyfin/config`
2. **Cache (optional)** → `/media/data/jellyfin/cache`
3. **Media files** → `/media/data/media` (or wherever your movies/music/TV shows are)

> The most important is the `/config` folder — it contains the database and metadata.

---

### 🔹 2. Backup Command

Run this on the host:

```bash
# Create a backup folder (e.g., on another drive or external disk)
mkdir -p /media/backup/jellyfin

# Backup configs and cache
sudo rsync -a /media/data/jellyfin/config /media/backup/jellyfin/config
sudo rsync -a /media/data/jellyfin/cache /media/backup/jellyfin/cache

# Optional: backup media (if you want a full copy)
sudo rsync -a /media/data/media /media/backup/jellyfin/media
```

This keeps ownership (`uid/gid`) intact, so restoring is easier.

---

### 🔹 3. Automated Backup (Optional)

You can create a simple cron job to back up daily:

```bash
crontab -e
```

Add:

```cron
0 3 * * * rsync -a /media/data/jellyfin/config /media/backup/jellyfin/config
0 3 * * * rsync -a /media/data/jellyfin/cache /media/backup/jellyfin/cache
```

This runs every day at 3 AM.

---

### 🔹 4. Restore Jellyfin

If you ever need to restore:

1. Stop the Jellyfin container:

```bash
docker stop jellyfin
```

2. Restore the folders:

```bash
sudo rsync -a /media/backup/jellyfin/config /media/data/jellyfin/config
sudo rsync -a /media/backup/jellyfin/cache /media/data/jellyfin/cache
# Optional: restore media if needed
sudo rsync -a /media/backup/jellyfin/media /media/data/media
```

3. Make sure permissions are correct:

```bash
sudo chown -R 1000:1000 /media/data/jellyfin
sudo chown -R 1000:1000 /media/data/media
```

4. Start Jellyfin container:

```bash
docker start jellyfin
```

Your library, metadata, watch progress, and logs will be fully restored.

---

### 🔹 5. Tips

* Always backup **before updating Jellyfin**, in case an update breaks something.
* Keep a **secondary backup** (another external disk or cloud) for disaster recovery.
* If your media library is huge, consider backing up only **config**, since media can usually be restored from the original source.

---

✅ Now you have a **complete setup**:

* Jellyfin running in Portainer
* External disk accessible
* Configs, cache, and media properly mounted
* Backup & restore procedure in place

---
