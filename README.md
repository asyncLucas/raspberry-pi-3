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

## VPN

- [PipVPN](https://www.pivpn.io/)
- [Build your own private WireGuard VPN with PiVPN](https://www.jeffgeerling.com/blog/2023/build-your-own-private-wireguard-vpn-pivpn)

## Network Ad Blocking

- [AdGuard Home](https://adguard.com/en/adguard-home/overview.html)
- [Pi-hole﻿®﻿﻿](https://pi-hole.net/)
