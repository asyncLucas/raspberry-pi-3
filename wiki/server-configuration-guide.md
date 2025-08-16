# 🖥️ Server Configuration Guide

This guide documents the step-by-step setup of a Linux server with networking, shared storage, VPN access, and local DNS resolution.

---

## 1. 🔄 System Update

Before starting any configuration, update the system packages:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. 🌐 Network Configuration (Netplan)

**Edit Netplan configuration file:**

```bash
cd /etc/netplan
sudo nano 50-cloud-init.yaml
```

Adjust the file for your static IP, gateway, and DNS (example):

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

**Apply changes and reboot:**

```bash
sudo netplan apply
sudo shutdown -r now
```

**Verify network:**

```bash
ip a
curl icanhazip.com
```

---

## 3. 💾 Mounting Storage Permanently

**Identify the drive:**

```bash
sudo blkid
```

**Create mount point:**

```bash
sudo mkdir /media/data
```

**Edit `/etc/fstab`:**

```bash
sudo nano /etc/fstab
```

Add a line (replace UUID with your drive’s):

```
UUID=xxxx-xxxx /media/data ext4 defaults 0 2
```

**Mount all entries:**

```bash
sudo mount -a
systemctl daemon-reload
```

---

## 4. 📂 Samba File Sharing

**Install Samba:**

```bash
sudo apt install samba
```

**Edit Samba config:**

```bash
sudo nano /etc/samba/smb.conf
```

Example share:

```ini
[data]
   path = /media/data
   writeable = yes
   browseable = yes
   guest ok = no
```

**Set Samba password:**

```bash
sudo smbpasswd -a lucas
```

**Allow Samba in firewall:**

```bash
sudo ufw allow samba
```

**Restart service:**

```bash
sudo service smbd restart
sudo service smbd status
```

---

## 5. 🔐 PiVPN (WireGuard) Setup

**Install PiVPN:**

```bash
curl -L https://install.pivpn.io | bash
```

Follow on-screen setup, choosing WireGuard.

**Manage clients:**

```bash
pivpn add      # Add client
pivpn list     # List clients
pivpn -qr      # Show QR code
```

**Edit WireGuard config:**

```bash
sudo nano /etc/wireguard/wg0.conf
```

Restart service:

```bash
sudo systemctl restart wg-quick@wg0
sudo systemctl status wg-quick@wg0
```

---

## 6. 🏠 Local DNS with Dnsmasq

**Install dnsmasq:**

```bash
sudo apt install dnsmasq
```

**Disable `systemd-resolved`:**

```bash
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
```

**Create local config:**

```bash
sudo nano /etc/dnsmasq.d/local.conf
```

Example:

```
address=/server.home/192.168.1.100
```

**Restart and enable dnsmasq:**

```bash
sudo systemctl restart dnsmasq
sudo systemctl enable --now dnsmasq
```

**Test DNS:**

```bash
nslookup server.home 127.0.0.1
dig @127.0.0.1 server.home
```

---

## 7. 📋 Useful Commands Reference

* **Check DNS service:**

  ```bash
  sudo systemctl status dnsmasq
  ```
* **Flush DNS cache:**

  ```bash
  sudo systemd-resolve --flush-caches 2>/dev/null || sudo resolvectl flush-caches
  ```
* **Check port 53 usage:**

  ```bash
  sudo ss -tuln | grep :53
  ```
* **View configs:**

  ```bash
  cat /etc/resolv.conf
  cat /etc/dnsmasq.d/*.conf
  ```
