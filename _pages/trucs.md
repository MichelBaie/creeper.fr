---
layout: page
title: Plein de Trucs en vrac...
description: plein de choses
---

# Clé SSH

https://creeper.fr/ssh.key

```bash
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDKyJSe0d7Z+KTGlAMwWFn+LC6UbrpPsvWuRmxTaeBjt tbringuier_2025
```

# Cloudflare Warp

Permet de faire passer tout son traffic par Cloudflare et ainsi bénéficier d’un bien meilleur peering à l’international.

[Télécharger ici](https://one.one.one.one/)

# Marionnet

![Marionnet VM](https://forevercdn.creeper.fr/img/marionnet.avif)

Machine virtuelle [Debian](https://www.debian.org/) 11 avec le logiciel [Marionnet](https://marionnet.org/site/index.php/fr/) installé dessus en démarrage automatique.

Disponible pour [VMWare](https://r2cdn.creeper.fr/Marionnet-VMWARE.ova) et [VirtualBox](https://r2cdn.creeper.fr/Marionnet-VBOX.ova). Fichiers OVA hébergés chez Cloudflare R2 🚀

# IUT Brandings

Les brandings de l’IUT de Villetaneuse au format .svg -> [ici](https://forevercdn.creeper.fr/zip/IUT-Brandings.zip)

# WatchTower

```yml
services:
  watchtower:
    container_name: watchtower
    image: containrrr/watchtower
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
    restart: unless-stopped
    environment:
      - WATCHTOWER_CLEANUP=true
      - TZ=Europe/Paris
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_POLL_INTERVAL=3600
      - WATCHTOWER_ROLLING_RESTART=true
```

# Mises à jour automatiques

```
MAILTO=""
0 * * * * DEBIAN_FRONTEND=noninteractive apt update -qq && \
          DEBIAN_FRONTEND=noninteractive apt full-upgrade -y -qq > /dev/null 2>&1
```

