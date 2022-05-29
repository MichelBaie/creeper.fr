---
layout: post
title: Désactiver l'IPv6  sur un Linux
description: L'IPv6 peut poser des soucis lors d'un routage très spécifique ou bien même causer des fuites.
tags: [ipv6]
---

Hello !

Je déploie beaucoup de Ubuntu/Debian chez moi et très souvent je n'ai pas besoin de l'IPv6.
Voici quelques commandes simples pour la désactiver définitivement :

```
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
```
