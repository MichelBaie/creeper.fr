---
layout: post
title: Faire du PCI Passtrough sur ESXI 7.0
description: Il est nécessaire d'ajouter quelques arguments afin de pouvoir faire marcher le PCI Passtrough sur ESXi.
tags: [esxi]
---

Hello !

J'ai récemment fait du PCI Passtrough sur mon serveur pour jouer dessus via Parsec.
Il est nécessaire d'ajouter les arguments suivants à la configuration de la VM pour bien faire marcher les GPU NVIDIA :

```
hypervisor.cpuid.v0 = FALSE
```

Il faut rajouter ces arguments dans les paramètres de la Machine Virtuelle :

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919458906198036/firefox_SQmpH7euze.png)

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919376551034930/firefox_BKR927lYtN.png)

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919272762970174/firefox_nfWxg5PCEp.png)
