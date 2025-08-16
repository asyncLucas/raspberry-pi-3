# Checking who is connected to your server (via **SSH**, **Samba**, or **VPN**)

Here are the main ways depending on the service:

---

## 👤 Check SSH Connections

```bash
who
```

Shows logged-in users.

```bash
w
```

More detailed: users, login time, remote IP.

```bash
ss -tulpn | grep ssh
```

Lists active connections on the SSH port.

```bash
journalctl -u ssh --since "10 minutes ago"
```

Check recent SSH logins.

---

## 📂 Check Samba Connections

```bash
sudo smbstatus
```

Shows:

* Who is connected
* From which IP
* Which shares/files are being accessed

---

## 🔐 Check VPN (WireGuard / PiVPN) Connections

```bash
pivpn list
```

Lists clients and their status.

For WireGuard directly:

```bash
sudo wg show
```

Shows connected peers, their public keys, last handshake, and data transferred.

---

## 🌐 General Network Connections

```bash
ss -tulpn
```

Lists all listening ports and active connections.

```bash
sudo lsof -i
```

Lists processes using network sockets.

---

⚡ Quick summary:

* **SSH** → `w` or `who`
* **Samba** → `smbstatus`
* **VPN** → `pivpn list` or `wg show`
