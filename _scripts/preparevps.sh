#!/bin/bash

# Vérifier l'état du service networking.service

if systemctl is-enabled networking; then
  echo "Le réseau du VPS est prêt ! Vous pouvez continuer la documentation."
else
  echo "Le réseau du VPS nécessite une modification. Veuillez patienter..."
  apt install ifupdown net-tools resolvconf bash curl arping wget -y
  apt-get purge netplan.io --autoremove -y
  cloud-init clean
  cloud-init init
  systemctl unmask networking
  systemctl enable networking resolvconf
  systemctl stop systemd-networkd.socket systemd-networkd systemd-networkd-wait-online
  systemctl disable systemd-networkd.socket systemd-networkd systemd-networkd-wait-online
  systemctl mask systemd-networkd.socket systemd-networkd systemd-networkd-wait-online
  rm /etc/resolv.conf
  ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
  systemctl start networking
  echo "Le réseau du VPS est prêt ! Le VPS redémarre, reconnectez-vous."
  echo "Les clés SSH peuvent avoir changé : pas de panique."
  reboot
fi