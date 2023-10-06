---
layout: post
title: Qu'est-ce qu'un reverse proxy et comment l'utiliser ?
description: On entends souvent parler de proxy ou reverse proxy pour se protéger, mais c'est quoi au fait ?
summary: reverse proxy
tags: [tunnel,nginxproxymanager,npm,proxy,reverse proxy,homelab]
---

Dans le monde de l’auto-hébergement, beaucoup de personnes parlent et utilisent un reverse proxy. Mais c’est quoi ?
Dans cet article, je vais tout d’abord vous présenter ce qu’est un reverse proxy, ses intérêts et cas d’usages; puis vous proposer un guide sur comment en mettre en place un.

## C’est quoi un reverse proxy ?

Un reverse proxy, ou proxy inverse en français, est un serveur intermédiaire pour accéder à un autre serveur. Puisqu’une image vaut milles mots, voici un schéma provenant du site de CloudFlare :

![](https://cdn.discordapp.com/attachments/926788575293472798/1137435345760301086/UVEcKcxJiI.png)

Il y a plusieurs intérêts à utiliser un reverse proxy :

* 1 seul serveur à exposer sur internet
* ainsi, moins de surface d’attaques
* centralisant tout le traffic, une grosse journalisation
* gestion des accès / firewalling plus pratique

Dans le cadre d’un HomeLab, l’intérêt est de pouvoir faire passer tous les services utilisant du web HTTP/HTTPS par un seul port 80/443 et ainsi y accéder depuis l’extérieur.

Le service CloudFlare est indirectement un reverse proxy, ils offrent du transit via leurs serveurs, afin de se protéger d’attaques DDOS, pour ensuite rediriger vers notre serveur.

Je recommande également ce genre de solutions si vous souhaiter facilement masquer votre IP au moindre coût, en installant un reverse proxy sur un VPS pour rediriger vers votre box.

## Différentes solutions existent

Pour “reverse-proxiser” notre traffic, il existe beaucoup de services.
Le plus connu est sans doute NGINX, un célèbre serveur web qui peut également proxiser du traffic HTTP/TCP/UDP.
Mais il en existe également d’autres, Caddy ou Traefik qui sont orientés strictement proxying et s’intègrent très bien avec les environnements docker.

Cet article se focalisera sur NGINX, et plus particulièrement sur un très joli frontend créé par la communauté : Nginx Proxy Manager.

## NginxProxyManager

![](https://cdn.discordapp.com/attachments/926788575293472798/1137438897383669902/logo.png)

Nginx Proxy Manager est un frontend permettant de gérer de manière très simple du traffic en tout genre via une interface web ergonomique et intuitive.

Il se déploie en une commande via le docker-compose suivant :

```yaml
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    network_mode: host
    environment:
      DISABLE_IPV6: 'true'
    volumes:
      - ./npm_data:/data
      - ./npm_letsencrypt:/etc/letsencrypt
```

(dans le docker-compose ci-dessus j’ai rajouté le network_mode en host pour pouvoir forward n’importe quel port tcp facilement)

## Comment utiliser Nginx Proxy Manager ?

Une fois le container docker déployé, rendez vous sur l’URL suivante :

http://ip:81

![](https://cdn.discordapp.com/attachments/926788575293472798/1137446852145447084/firefox_8NLblCrU40.png)

Puis connectez-vous avec les identifiants suivant :

```
Email : admin@example.com
Password : changeme
```

Une fois dans l’interface, créez votre premier compte administrateur, et changez le mot de passe par défaut.

![](https://cdn.discordapp.com/attachments/926788575293472798/1137447131347701800/firefox_DB2VpqpDMd.png)

![](https://cdn.discordapp.com/attachments/926788575293472798/1137447630994157678/firefox_o8bSShYS9P.png)

Une fois sur la page d’accueil, plusieurs options s’offrent à vous :

![](https://cdn.discordapp.com/attachments/926788575293472798/1137447799902973962/firefox_fRSdnQdpjS.png)

* Proxy Hosts : Pour pouvoir gérer les sites HTTP/S qu’on souhaite faire transiter par notre reverse proxy. Par exemple vous pouvez faire en sorte que ip:port devienne service.votresite.fr
* Redirections Host : Permet d’associer un nom de domaine redir.votresite.fr à une autre URL via une redirection brute HTTP.
* Streams : Permet de faire du port forwarding TCP/UDP. Par exemple, si vous souhaitez que le port 25565 de votre VPS renvoie vers 1.1.1.1:25565
* 404 Hosts : Permet de renvoyer des code erreur 404 aux noms de domaines souhaités.

C’est donc rempli de fonctionnalités. Nous allons nous regarder les Proxy Hosts et les Streams.

Il y a également dans la barre de navigation supérieure la possibilité de gérer les comptes utilisateurs ayant accès à l’interface d’administration, des listes pour gérer des accès spécifiques aux sites, et la possibilité de gérer les certificats SSL pour l’HTTPS de nos sites.

### Proxy Hosts

