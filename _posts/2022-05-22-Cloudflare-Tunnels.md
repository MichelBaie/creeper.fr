---
layout: post
title: (non terminé) Cloudflare Tunnels, un Reverse Proxy directement depuis le Cloud
tags: [tunnel]
---

Cloudflare ont récemment sorti une interface web pour gérer leur service Cloudflare Tunnels.

Et ça marche vraiment bien !

# 1 - Présentation de Cloudflare Tunnels

CloudFlare, est un service proposant du cache ou des protections DDoS pour des services web.
Il marche directement au niveau des DNS et peut ainsi masquer l'adresse IP du serveur qui fais tourner le site.

Cependant, pour héberger un service, que ce sois chez soit où à la vue de tous, il faut ouvrir ses ports.
80 pour l'HTTP et 443 pour l'HTTPS.

Cela peut devenir compliqué quand on ne possède pas d'IP fixe ou que l'on ne souhaite pas du tout toucher à la configuration de sa box.

Et c'est là que Cloudflare Tunnels entre en jeu !

![BDES-1971_Argo-Tunnel-Diagrams_fr-FR](https://user-images.githubusercontent.com/39345534/169573785-c43d8412-3d0e-460b-a438-5a8f5aa78fd3.png)

Cloudflare Tunnels se connecte aux serveurs de Cloudflare, et ne nécessite aucune ouverture de ports.
![image-20220520184231674](image-20220520184231674.png)

Une fois connecté, il va s'occuper de rediriger le traffic des URLs vers les IPs concernées.
Tout est géré depuis le Cloud, et une seule commande de déploiement est nécessaire.

# 2 - Comment le déployer

Cette documentation portera seulement sur une 
