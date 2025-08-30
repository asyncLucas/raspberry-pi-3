#!/bin/bash
set -e

# === CONFIGURATION ===
BACKUP_DIR="/media/data/programs/Linux"
DATE=$(date +"%Y-%m-%d_%H-%M")
IMG_NAME="raspi_backup_$DATE.img"
IMG_PATH="$BACKUP_DIR/$IMG_NAME"
COMPRESSED_PATH="$IMG_PATH.gz"
DOC_PATH="$BACKUP_DIR/raspi_backup_instructions.md"

# === REQUIREMENTS CHECK ===
if ! command -v wget &> /dev/null; then
  echo "Installing wget..."
  sudo apt-get install -y wget
fi

if [ ! -f ./pishrink.sh ]; then
  echo "Downloading PiShrink..."
  wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh -O pishrink.sh
  chmod +x pishrink.sh
fi

# === DETECT ROOT DISK ===
ROOT_DISK=$(lsblk -no pkname $(findmnt -no source /) | head -n1)
DISK="/dev/$ROOT_DISK"

echo "=== Raspberry Pi Backup ==="
echo "Backing up from $DISK to $IMG_PATH"

# === CREATE RAW IMAGE ===
sudo dd if=$DISK of=$IMG_PATH bs=4M status=progress conv=fsync

# === SHRINK IMAGE ===
echo "=== Running PiShrink ==="
sudo ./pishrink.sh -a $IMG_PATH

# === COMPRESS IMAGE ===
echo "=== Compressing image ==="
gzip -f $IMG_PATH
echo "Backup completed: $COMPRESSED_PATH"

# === CREATE DOCUMENTATION ===
cat <<EOF | tee $DOC_PATH
# Raspberry Pi Backup & Restore

**Backup created on:** $DATE  
**Source disk:** $DISK  
**Backup file:** $COMPRESSED_PATH 