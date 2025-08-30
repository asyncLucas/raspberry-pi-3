# 💾 System Backup and Restore Guide

## Overview

This guide provides comprehensive instructions for backing up and restoring your Raspberry Pi system. The backup process creates a compressed, shrunk image that can be easily restored to any SD card larger than the used data.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Backup Process](#backup-process)
- [Restore Process](#restore-process)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- External storage device mounted
- System backup script (`system-backup.sh`)
- Sufficient storage space
- Root/sudo access

## Latest Backup Information

- **Date:** 2025-08-29_18-59
- **Source:** /dev/mmcblk0
- **Location:** /media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img.gz

---

## Backup Process

### 1. Prepare the Backup Script

```bash
chmod +x ~/raspi-backup.sh
```

### 2. Start the Backup

Execute the backup script in the background with logging:

```bash
nohup sudo ./system-backup.sh > backup.log 2>&1 &
```

### 3. Monitor Progress

Track the backup progress in real-time:

```bash
tail -f backup.log
```

### Output Location

The backup script will create a compressed image in:

```
/media/data/programs/Linux/raspi_backup_YYYY-MM-DD_HH-MM.img.gz
```

### Features

- Automatic image shrinking using PiShrink
- Compression to minimize storage space
- Background execution with logging
- Progress monitoring

---

## Restore Process

### 1. Identify Target Device

List available devices to identify your SD card:

```bash
lsblk
```

### 2. Prepare the Backup Image

Decompress the backup image:

```bash
gunzip /media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img.gz
```

### 3. Flash the Image

Write the image to the SD card:

```bash
sudo dd if=/media/data/programs/Linux/raspi_backup_2025-08-29_18-59.img of=/dev/sdX bs=4M status=progress conv=fsync
```

> ⚠️ **IMPORTANT**: Replace `/dev/sdX` with your SD card's device identifier. Using the wrong device can lead to data loss!

## Troubleshooting

### Common Issues

1. **Insufficient Space**

   - Ensure target SD card has enough capacity
   - Clear unnecessary files before backup

2. **Device Busy**

   - Unmount any mounted partitions
   - Close file managers or terminals accessing the device

3. **Permission Denied**
   - Verify sudo access
   - Check file permissions

### Notes

- Thanks to PiShrink, the backup can be restored to any SD card larger than the used data
- Always verify device identifiers before restoration
- Keep backup logs for reference

## Additional Resources

- [PiShrink Documentation](https://github.com/Drewsif/PiShrink)
- [DD Command Guide](https://wiki.archlinux.org/title/Dd)
- [Linux Device Management](https://wiki.archlinux.org/title/Device_file)
