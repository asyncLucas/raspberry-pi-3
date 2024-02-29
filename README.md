# Raspberry Pi 3

## Initial Steps

- [Raspberry Pi Imager](https://www.raspberrypi.com/software/) enables you to select an Ubuntu image when flashing your SD card.

## Operational System

- [Ubuntu Server](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#1-overview) (I'm using 22.04.3 LTS)

## Network Storage

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

## Grafana

- [Install Grafana on Raspberry Pi](https://grafana.com/tutorials/install-grafana-on-raspberry-pi/)
- [Monitoring Your Raspberry Pi System using InfluxDB Telegraf](https://randomnerdtutorials.com/monitor-raspberry-pi-influxdb-telegraf/)