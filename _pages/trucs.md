---
layout: page
title: Plein de Trucs en vrac...
description: plein de choses
---

# Clés SSH

Creeper :

```bash
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxpszvf6JtwApc4/c5PddoQ3ZGBiz+Y0WT6a0FPnb1xYpEBjo3p6Pl/DHFtzAzdEp+IymRzRGXA3tiCJf3KoThMyvqT1v0rNMAhRZKRnHPK4tBhaF3Yas9aCLwsiH767d5WVZNUlivq/IZkeSfEk7R3ybH/ZtQj9HCBzzfrXrlXKpKmayL9X8mw8n0lIDs12QbZBGbTEw7/E7Rz6+4ElIdJqVAvLsT0IC+2TRWaDxzDlbrV7ulEhZGKhdLR2jL5sSymgrqIxyE9RWv/Gin5gNF5h9OpY1rronWZHhTk/CMjBv4eIKKunGK1+5bmf2x+BhGtPF1srEQP+twTrgcvw3D
```

# Cloudflare Warp

Permet de faire passer tout son traffic par Cloudflare et ainsi bénéficier d’un bien meilleur peering.

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

