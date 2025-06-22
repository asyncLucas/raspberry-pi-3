# Raspberry Pi 3

## Initial Steps

- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) enables you to select an Ubuntu image when flashing your SD card.

## Operational System

- [Ubuntu Server](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#1-overview) (I'm using 22.04.3 LTS)

## Network Storage

- [Fixed IP]

```shell
network: 2
  version: 2
  renderer: networkd
  ethernets:
    eth0:
			dhcp4: no
			addresses:
				- 192.168.1.100/24 #desire ip
			routes:
				- to: default
					via: 192.168.1.1 #router home
			nameservers:
				addresses:
					- 8.8.8.8
					- 8.8.4.4
```

- [Fstab](https://help.ubuntu.com/community/Fstab)
    - The configuration file /etc/fstab contains the necessary information to automate the process of mounting partitions.
- [Install and Configure Samba](https://ubuntu.com/tutorials/install-and-configure-samba#1-overview)

```shell
[sambashare]
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

## Network Ad Blocking

- [AdGuard Home](https://adguard.com/en/adguard-home/overview.html)
    |   Filter      |                 URL                    |
    |---------------|----------------------------------------|
    | oisd          | https://oisd.nl/setup/adguardhome      |
    | GoodbyeAds    | https://github.com/jerryn70/GoodbyeAds |
- [Pi-hole﻿®﻿﻿](https://pi-hole.net/)

## Plex

- [Installation](https://support.plex.tv/articles/200288586-installation/)
    - Download Ubuntu 20.04 Arm64
    - [Enable repository updating for supported Linux server distributions](https://support.plex.tv/articles/235974187-enable-repository-updating-for-supported-linux-server-distributions/)

## VPN

- [PipVPN](https://www.pivpn.io/)
- [Build your own private WireGuard VPN with PiVPN](https://www.jeffgeerling.com/blog/2023/build-your-own-private-wireguard-vpn-pivpn)
    - [SSH into Wireguard Server](https://www.reddit.com/r/WireGuard/comments/q7lj5s/ssh_into_wireguard_server/?share_id%253DVeLF3uw-dGAJh5T3sOt9d%2526utm_content%253D1%2526utm_medium%253Dandroid_app%2526utm_name%253Dandroidcss%2526utm_source%253Dshare%2526utm_term%253D3)
    - [HOW TO USE WIREGUARD WITH UFW](https://www.procustodibus.com/blog/2021/05/wireguard-ufw/)

## Monitoring
- [Monitoring Your Raspberry Pi System using InfluxDB Telegraf](https://randomnerdtutorials.com/monitor-raspberry-pi-influxdb-telegraf/)

## Coding
- [Programming Raspberry Pi Remotely using VS Code (Remote-SSH)](https://randomnerdtutorials.com/raspberry-pi-remote-ssh-vs-code/)

## Terminal
- [Install and Setup ZSH on Ubuntu Linux](https://itsfoss.com/zsh-ubuntu/)