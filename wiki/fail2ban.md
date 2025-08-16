Nice move 🔐 — **Fail2ban** is a great way to protect your server from brute-force attacks (SSH, Samba, etc.).
Here’s a full step-by-step install + configuration guide for Ubuntu/Debian:

---

## 1. 📦 Install Fail2ban

```bash
sudo apt update
sudo apt install fail2ban -y
```

Check service:

```bash
sudo systemctl status fail2ban
```

---

## 2. ⚙️ Configure Fail2ban

### Don’t edit `jail.conf` directly ⚠️

Instead, create/edit the **override file**:

```bash
sudo nano /etc/fail2ban/jail.local
```

### Example config (basic SSH protection):

```ini
[DEFAULT]
# Ban time in seconds (e.g. 10 minutes)
bantime = 600

# Findtime = how far back to look for failed attempts
findtime = 600

# Max retries before ban
maxretry = 5

# Where to log bans
logtarget = /var/log/fail2ban.log

# Email alerts (optional)
destemail = you@example.com
sender = fail2ban@server.home
mta = sendmail

# Action = what to do when banning
action = %(action_)s

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
backend = systemd
```

Save & exit.

---

## 3. 🔄 Restart Fail2ban

```bash
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

---

## 4. ✅ Verify it’s working

Check status:

```bash
sudo fail2ban-client status
```

Check SSH jail details:

```bash
sudo fail2ban-client status sshd
```

You should see:

* Filter in use
* Currently banned IPs

---

## 5. 🔧 Useful Commands

* Ban an IP manually:

  ```bash
  sudo fail2ban-client set sshd banip 192.168.1.50
  ```
* Unban an IP:

  ```bash
  sudo fail2ban-client set sshd unbanip 192.168.1.50
  ```
* Check log:

  ```bash
  tail -f /var/log/fail2ban.log
  ```

---

## 6. (Optional) Protect other services

You can enable jails for **Samba, PiVPN, DNS** etc. Example for Samba:

```ini
[samba]
enabled = true
port = 137,138,139,445
logpath = /var/log/samba/log.smbd
maxretry = 5
```

---

✅ With this, your server will **auto-ban attackers** that fail too many login attempts.
