# 🏠 Home Server on Raspberry Pi 3

<div align="center">

[![Ubuntu Server](https://img.shields.io/badge/Ubuntu%20Server-22.04%20LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![ArgoCD](https://img.shields.io/badge/argo%20cd-%23EF7B4D.svg?style=for-the-badge&logo=argo&logoColor=white)](https://argo-cd.readthedocs.io/)

</div>

## 📑 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Directory Structure](#-directory-structure)
- [Quick Start](#-quick-start)
- [Documentation](#-documentation)
- [Services](#-services)
- [Contributing](#-contributing)

## 🔍 Overview

This repository contains the complete configuration and documentation for a home server setup using a Raspberry Pi 3, running Ubuntu Server 22.04 LTS. The setup includes Kubernetes cluster management, media streaming, network monitoring, ad blocking, and more.

## ✨ Features

- **Network Management**
  - Static IP configuration
  - Network monitoring with Netdata
  - Ad blocking with AdGuard Home
  - VPN access with PiVPN
- **Container Management**
  - Kubernetes cluster
  - ArgoCD for GitOps
  - Portainer for Docker management
- **Media & Storage**
  - Jellyfin media server
  - Samba file sharing
  - Automated backup system
- **Monitoring & Security**
  - Grafana dashboards
  - Fail2ban protection
  - Circuit breaker implementation
  - Telegraf monitoring

## 📁 Directory Structure

| Directory        | Description                                     |
| ---------------- | ----------------------------------------------- |
| `/bootstrap`     | Initial setup and installation scripts          |
| `/docker`        | Docker service configurations and documentation |
| `/helm-releases` | Helm release configurations                     |
| `/helm-values`   | Helm chart values                               |
| `/manifests`     | Kubernetes manifest files                       |
| `/router`        | Network and router configuration guides         |
| `/scripts`       | Utility scripts for maintenance                 |
| `/wiki`          | Detailed documentation and guides               |

## 🚀 Quick Start

1. Flash Ubuntu Server using [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

- [Ubuntu Server](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#1-overview) (I'm using 22.04.3 LTS)

## Network

- [Fixed IP]

```shell
sudo nano /etc/netplan/50-cloud-init.yaml
```

```shell
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24   # desired IP
      routes:
        - to: default
          via: 192.168.1.1   # router home
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

⚡ Steps after saving:

```shell
sudo netplan try   # safer, reverts if fails
sudo netplan apply
```

👉 “The server at 192.168.1.100 no longer matches the fingerprint I had saved before. This could mean an attack, but more likely you just reinstalled or reset the SSH server.”

### Option 1: Remove the old host key (simplest)

```shell
ssh-keygen -R 192.168.1.100
```

### Limit access to sensitive services

1. Use iptables / nftables directly (native Linux firewall):

```shell
# Example: allow SSH only from local network
sudo iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
```

> Similar rules can be applied for Portainer, Samba, DNS, etc.

### Ad Blocking

- [AdGuard Home](https://adguard.com/en/adguard-home/overview.html)
  | Filter | URL |
  |---------------|----------------------------------------|
  | oisd | https://oisd.nl/setup/adguardhome |
  | GoodbyeAds | https://github.com/jerryn70/GoodbyeAds |
- [Pi-hole﻿®﻿﻿](https://pi-hole.net/)

## File sharing

- [Fstab](https://help.ubuntu.com/community/Fstab)
  - The configuration file /etc/fstab contains the necessary information to automate the process of mounting partitions.
- [Install and Configure Samba](https://ubuntu.com/tutorials/install-and-configure-samba#1-overview)

```shell
[sambashare] # mapped name to connect later e.g.: smb://192.168.1.100/sambashare
    comment = Samba on Ubuntu
    path = /path/to/mounted/disk
    read only = no
    browsable = yes
    guest ok = no
    valid users = YOUR_USERNAME
    force create mode = 770
    force directory mode = 770
    inherit permissions = yes
```

## VPN

### Setup DNS

- [DuckDNS](https://gist.github.com/taichikuji/6f4183c0af1f4a29e345b60910666468)
- [Port Forwarding Testing](https://www.yougetsignal.com/tools/open-ports/)

### PiVPN

- [PipVPN](https://www.pivpn.io/)
- [Build your own private WireGuard VPN with PiVPN](https://www.jeffgeerling.com/blog/2023/build-your-own-private-wireguard-vpn-pivpn)
  - [SSH into Wireguard Server](https://www.reddit.com/r/WireGuard/comments/q7lj5s/ssh_into_wireguard_server/?share_id%253DVeLF3uw-dGAJh5T3sOt9d%2526utm_content%253D1%2526utm_medium%253Dandroid_app%2526utm_name%253Dandroidcss%2526utm_source%253Dshare%2526utm_term%253D3)
  - [HOW TO USE WIREGUARD WITH UFW](https://www.procustodibus.com/blog/2021/05/wireguard-ufw/)

## Monitoring

- [NetData](./wiki/netdata.md)
- [InfluxDB Telegraf](https://randomnerdtutorials.com/monitor-raspberry-pi-influxdb-telegraf/)

## Coding

- [Programming Raspberry Pi Remotely using VS Code (Remote-SSH)](https://randomnerdtutorials.com/raspberry-pi-remote-ssh-vs-code/)

## Terminal

- [Install and Setup ZSH on Ubuntu Linux](https://itsfoss.com/zsh-ubuntu/)

## 🔄 Making the system auto-recover

### Enable automatic reboot on kernel panic

Edit /etc/sysctl.conf:

```shell
kernel.panic = 10
```
