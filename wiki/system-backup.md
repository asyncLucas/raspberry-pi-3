# Raspberry Pi Backup & Restore

**Backup created on:** 2025-08-29_18-59  
**Source disk:** /dev/mmcblk0  
**Backup file:** /media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img.gz

---

## 🔹 How to Backup Again

### Give script permissions

```bash
chmod +x ~/raspi-backup.sh
```

### Run the backup script:

```bash
nohup sudo ./system-backup.sh > backup.log 2>&1 &
```

### Check logs

```bash
tail -f backup.log
```

This will create a new shrunk + compressed image in:
`/media/data/programs/Linux`

---

## 🔹 How to Restore

1. Identify your SD card device (e.g. /dev/sdb):

   ```bash
   lsblk
   ```

2. Decompress the backup image:

   ```bash
   gunzip /media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img.gz
   ```

   This will give you:
   `/media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img`

3. Flash the image back to an SD card:
   ```bash
   sudo dd if=/media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```
   > ⚠️ Replace **/dev/sdX** with the correct device for your SD card.

---

✅ Because the image was shrunk with PiShrink, you can restore it on any card that is **larger than the used data**, not necessarily the same size as the original.
