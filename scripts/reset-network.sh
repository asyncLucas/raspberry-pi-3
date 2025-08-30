#!/bin/bash
set -e

echo "==== Detectando interface de rede principal ===="
INTERFACE=$(ip route | grep default | awk '{print $5}')
echo "Interface detectada: $INTERFACE"

# Defina seu IP fixo desejado e gateway
STATIC_IP="192.168.1.100/24"
GATEWAY="192.168.1.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

echo "==== Resetando Netplan ===="
sudo rm -rf /etc/netplan/*

echo "==== Criando novo arquivo Netplan ===="
cat <<EOF | sudo tee /etc/netplan/50-cloud-init.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - $STATIC_IP
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
EOF

echo "==== Aplicando Netplan ===="
sudo netplan generate
sudo netplan apply

echo "==== Resetando DNS ===="
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
sudo systemctl restart systemd-networkd
sudo systemctl restart systemd-resolved

echo "==== Removendo PiVPN antigo ===="
if command -v pivpn &> /dev/null; then
    pivpn uninstall || true
fi
sudo rm -rf /etc/pivpn /etc/openvpn /etc/wireguard

echo "==== Instalando PiVPN do zero ===="
curl -L https://install.pivpn.io | bash

echo "==== Finalizado ===="
echo "Reinicie o servidor e depois rode 'pivpn add' para criar o primeiro cliente."