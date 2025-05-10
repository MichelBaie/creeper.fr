---
layout: post
title: Comment mettre en place un reverse proxy en toute sécurité avec l’aide d’un WAF (BunkerWeb) ?
description: Rédiger la description de la documentation
summary: Rédiger un sommaire
tags: [bunkerweb, waf, nginx, selfhosting, reverse-proxy]
permalink: /bunkerweb/
---

# Introduction


Depuis que je peux héberger toutes sortes d’applications accessibles via des adresses IPv4 publiques, la question de leur sécurité est devenue centrale.

Beaucoup se tournent vers NGINX — parfois accompagné d’interfaces conviviales comme **NGINX Proxy Manager** — ou vers d’autres reverse proxies tels que **Caddy** ou **HAProxy**. Pourtant, ces solutions restent peu sécurisées par défaut.

Un certificat SSL assure certes le chiffrement des échanges, empêchant l’interception des données sensibles (sauf en cas d’attaque MITM), mais la sécurité ne s’arrête pas là : de nombreux autres aspects doivent être pris en compte !

Il faut notamment se prémunir contre les exploits applicatifs, par exemple les injections SQL, le cross-site scripting ou l’élévation de privilèges. Un reverse proxy se contente de relayer le trafic ; s’il n’intègre pas de protections, il transmettra l’exploit sans sourciller.

La généralisation de l’hébergement via des conteneurs Docker offre un certain niveau d’isolation, mais une application compromise reste une porte d’entrée potentielle pour la fuite de données.

Il existe aussi des WAF grand public et professionnels, comme **Cloudflare**, qui proposent gratuitement de nombreuses fonctionnalités d’atténuation. Malheureusement, ces solutions sont souvent mal déployées (par ex. : non-restriction des IP à celles de Cloudflare) et soulèvent des questions éthiques : confier son trafic à une société américaine, c’est accepter un intermédiaire puissant, ce qui, dans le contexte politique actuel, peut prêter à débat.

Toutes ces réflexions m’ont conduit à chercher un WAF simple d’utilisation et souverain 🇫🇷, et c’est ainsi que j’ai découvert **[BunkerWeb](https://bunkerweb.io)** !

# Présentation de BunkerWeb
**[BunkerWeb](https://bunkerweb.io)** est un pare-feu d’applications Web (Web Application Firewall) open-source de nouvelle génération qui fonctionne comme un reverse-proxy complet basé sur NGINX. Il est développé et maintenu par Bunkerity, entreprise française spécialisée en cybersécurité, ce qui inscrit la solution dans une démarche de souveraineté numérique. Publié sous licence AGPL v3, son code reste entièrement auditable et modifiable, garantissant à chacun la maîtrise de ses briques de sécurité et de leur évolution.

Conçu pour la souveraineté « jusqu’au bout », BunkerWeb est totalement auto-hébergeable : il se déploie on-premise sur un Linux ou via Docker. Sans aucune dépendance à un SaaS externe, toutes les règles, journaux et clés TLS demeurent sous votre contrôle, répondant aux exigences les plus strictes en matière de résidence et de conformité des données.

Par défaut, BunkerWeb protège vos services « secure by default » : intégration de ModSecurity et de l’OWASP CRS, durcissement TLS, bannissement automatique des comportements anormaux, défi aux robots, rate limiting, blacklists IP externes et bien plus. Un système de plugins permet d’étendre les capacités (PHP, notifications, etc.), tandis que l’interface Web simplifie la gestion quotidienne depuis n’importe où.

Après avoir examiné l’ensemble des critères évoqués plus haut et échangé avec plusieurs développeurs lors du FIC, j’ai décidé de déployer BunkerWeb dans mon homelab. Quelques mois plus tard, le bilan est sans appel : j’en suis pleinement satisfait.

Dans cet article, nous verrons pas à pas comment installer et configurer BunkerWeb.

# Pré-requis

BunkerWeb peut s’exécuter sur n’importe quel environnement Docker. Prévoyez au minimum 2 vCPU et 4 Go de RAM pour un usage standard ; dans des contextes plus exigeants, préférez plutôt 4 vCPU et 16 Go de RAM.

La mémoire est mise à contribution parce qu’un processus ModSecurity dédié est lancé pour chaque sous-domaine — une option que l’on peut désactiver sur les machines disposant de peu de RAM, comme nous le verrons plus loin.

La charge CPU, quant à elle, provient surtout du chiffrement avancé et des optimisations à la volée (compression GZip ou Brotli), qui allègent le poids des fichiers transmis aux clients au prix d’un surcroît de calcul.

Pour le trafic réseau, pensez à autoriser les ports 80/TCP, 443/TCP et 443/UDP. Le port 443 en UDP est indispensable pour la prise en charge de HTTP/3 : le futur 🚀 est à nos portes !

Assurez-vous également de créer un enregistrement DNS pour l’interface d’administration Web ; disposer de cette entrée dès le départ permet d’effectuer la configuration initiale de BunkerWeb directement depuis l’URL correspondante. De même, chaque sous-domaine que vous protégerez avec BunkerWeb devra auparavant avoir son enregistrement DNS approprié.

Une fois ces prérequis validés, passons au déploiement de notre WAF !

# Déploiement de BunkerWeb avec Docker Compose


Commencez par créer un fichier `compose.yaml`, puis copiez-y le bloc de configuration ci-dessous :

```yaml
x-bw-env: &bw-env
  API_WHITELIST_IP: "127.0.0.0/8 10.20.30.0/24"
  # !! IMPORTANT !! changez le mot de passe par défaut. (en dessous dans le compose également)
  DATABASE_URI: "mariadb+pymysql://bunkerweb:motdepasseachanger@bw-db:3306/db"
services:
  bunkerweb:
    image: bunkerity/bunkerweb:latest
    ports:
      - "80:8080/tcp"   # HTTP (TCP)
      - "443:8443/tcp"  # HTTPS (TCP)
      - "443:8443/udp"  # HTTP(S)/3 (UDP)
    environment:
      <<: *bw-env
    restart: unless-stopped
    networks:
      - bunker
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
  bw-scheduler:
    image: bunkerity/bunkerweb-scheduler:latest
    environment:
      <<: *bw-env
      BUNKERWEB_INSTANCES: "bunkerweb"
      SERVER_NAME: ""
      MULTISITE: "yes"
      UI_HOST: "http://bw-ui:7000"
    volumes:
      - bw-data:/data
    restart: unless-stopped
    networks:
      - bunker
      - bunker-db
  bw-ui:
    image: bunkerity/bunkerweb-ui:latest
    environment:
      <<: *bw-env
    restart: unless-stopped
    networks:
      - bunker
      - bunker-db
  bw-db:
    image: mariadb:11
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: "db"
      MYSQL_USER: "bunkerweb"
      # Mot de passe du compte applicatif (à changer !)
      MYSQL_PASSWORD: "motdepasseachanger"
    volumes:
      - bw-dbdata:/var/lib/mysql
    restart: unless-stopped
    networks:
      - bunker-db
networks:
  bunker:
    name: bunker
    ipam:
      driver: default
      config:
        - subnet: 10.20.30.0/24
  bunker-db:
    name: bunker-db
volumes:
  bw-data:
  bw-dbdata:
```

N’oubliez pas de changer le mot de passe "motdepasseachanger" par un autre plus sécurisé 🔐 ! Vous pouvez également le faire avec la commande suivante (qui génère un mot de passe aléatoire de 32 caractères et remplace compose.yaml à votre place) :

```shell
sed -i -e "s|motdepasseachanger|$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c32)|g" -e 's/[[:space:]]\+#.*$//' -e '/^[[:space:]]*$/d' compose.yaml
```

Une fois le fichier compose.yaml prêt, il vous suffit de `docker compose up -d` puis passez à la première configuration via l’interface web !

Le premier démarrage peut prendre un certain temps, vous pouvez observer l’avancement via les logs avec la commande suivante : `docker compose logs --follow`

# Premier démarrage via l’interface web

Rendez vous sur https://url-de-votre-bunker.web/setup afin de retrouver la page de démarrage suivante :

![bunkerweb-setup1.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup1.avif)

Dans un premier temps vous devez renseigner les propriétés du compte administrateur.

![bunkerweb-setup2.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup2.avif)

Ensuite, vous devez renseigner le hostname public de votre instance BunkerWeb. Attention !! Il ne faut surtout pas toucher à UI Host et UI URL !!

En ce qui en est de la gestion des certificats SSL, l’implémentation de Let’s Encrypt est très simple d’utilisation ! Il vous suffit de cocher « Auto Let’s Encrypt » pour que cela soit géré de manière automatique, et de mentionner un mail pour recevoir les informations Let’s Encrypt.

Vous avez aussi la possibilité de demander des certificats SSL via DNS, permettant ainsi donc l’usage de Wildcards (`*.votredomaine.tld`). Pour cela, séléctionnez comme Challenge Type « dns » et choisissez votre DNS Provider puis renseignez la clé d’API adéquate.

![bunkerweb-setup3.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup3.avif)

Une fois toutes les informations renseignées, BunkerWeb propose un récapitulatif des paramètres renseignés précédemment. Vous pouvez valider et lancer l’installation.

![bunkerweb-setup4.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup4.avif)


Après avoir patienté le temps de la mise en place de BunkerWeb, vous devriez tomber sur la page de login de l’interface de gestion. Vous pouvez vous y connecter.

# Présentation de l’interface web et paramétrage rapide

Bienvenue sur l’interface web de BunkerWeb !

![bunkerweb-interface1.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-interface1.avif)


Sur la page d’acceuil, vous retrouverez quelques statistiques essentielles liées à votre instance. Dans la barre lattérale gauche se trouve les menus suivants :

- Home : Acceuil
- Instances : Uniquement utile pour un cluster, c’est dans cette rubrique que sont renseignées les différentes instances composant le cluster
- Global Config : Gérer la configuration générale et commune à tous les services de BunkerWeb
- Services : Gérer la configuration de chaque VirtualHost / server géré par BunkerWeb
- Configs : Gérer des configurations NGINX avancées
- Plugins : Gérer les modules supplémentaires de BunkerWeb
- Cache : Gérer les fichiers mis en cache par BunkerWeb (pour son fonctionnement, pas cache HTTP)
- Reports : Consulter les alertes et blocages effectués par BunkerWeb
- Bans : Consulter les bannissements effectués par BunkerWeb
- Jobs : Gérer les tâches planifiées de BunkerWeb
- Logs : Consulter les fichiers de journalisation de BunkerWeb

Les catégories principales que j’utilise régulièrement sont Global Config, Services et Bans / Report.

Nous allons maintenant passer en revue quelques paramètres pratiques sur BunkerWeb, pour se faire, rendez-vous dans la rubrique « Global Config »

![bunkerweb-interface2.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-interface2.avif)

En haut à gauche, dans le menu déroulant, il est possible de consulter la configuration globale de chaque plugins.
En haut à droite, le bouton Save permet d’enregistrer les modifications.

Voici une liste non exhaustive de paramètres que j’ai modifié sur mon paramètre :

### Rubrique General :

« LISTEN_STREAM » -> false
« USE_TCP » -> false
« USE_UDP » -> false

### Rubrique Brotli :

« USE_BROTLI » -> true
Permet d’activer l’algorithme de compression avancé Brotli pour réduire la taille des fichiers transférés par BunkerWeb. Ajuster ensuite les paramètes à votre guise.

### Client Cache :

« USE_CLIENT_CACHE » -> true
Permet d’activer le cache côté client et ainsi moins solliciter le serveur.

### Gzip :

« USE_GZIP » -> true
Permet d’activer l’algorithme de compression très répandu Gzip pour réduire la taille des fichiers transférés par BunkerWeb. Ajuster ensuite les paramètes à votre guise.

### Let’s Encrypt

« AUTO_LETS_ENCRYPT » -> true
« EMAIL_LETS_ENCRYPT » -> mail@pourles.certificats
Permet de pré-remplir les champs de configuration Let’s Encrypt lors de la création d’un service. Ajuster les paramètres en fonction de votre environnement.

### ModSecurity

« USE_MODSECURITY_GLOBAL_CRS » -> true (UNIQUEMENT SI VOUS AVEZ PEU DE RESSOURCES RAM)

### Reverse Proxy

« REVERSE_PROXY_INTERCEPT_ERRORS » -> false (Affiche l’erreur du service plûtot que celle de BunkerWeb, j’ai eu des soucis avec Guacamole)

### SSL

« REDIRECT_HTTP_TO_HTTPS » -> true
« SSL_PROTOCOLS » -> TLSv1.3

Maintenant que nous avons passé en revue les paramètres essentiels, voyons comment déployer un service type.

# Déploiement d’un service web

Il est important d’avoir configuré au préalable l’enregistrement DNS lié au service que vous allez créé. Cela sera utile pour la création du certificat Let’s Encrypt.

Rendez-vous dans la rubrique « Services » puis commencez en cliquant sur « Create new service »

## Étape 1 : Web service - Front service

![bunkerweb-createservice1.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice1.avif)
Dans cette étape, vous devez renseigner un « SERVER_NAME » ainsi que les paramètres de Let’s Encrypt (si AUTO_LETS_ENCRYPT n’est pas à true).
Il vous est également possible de séléctionner une Template avec différent niveaux de sécurité en fonction de la criticité de l’application.
Ce sont les paramètres de la partie publique du reverse proxy, visible depuis l’extérieur.

## Étape 2 : Web service - Upstream server

![bunkerweb-createservice2.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice2.avif)

Dans cette étape, vous devez renseigner un « REVERSE_PROXY_HOST » qui est l’URL du service, sur votre réseau interne, que vous souhaitez ouvrir à l’extérieur. Faites bien attention à préciser HTTP ou HTTPS si jamais le service est joignable en HTTPS en local !! Cela n’impacte pas l’extérieur !
Également, je vous recommande d’activer « REVERSE_PROXY_WS » pour activer le support des Websockets. Beaucoup d’application utilisent cette fonctionnalité du protocole HTTP.

## Étape 3 : HTTP - General

![bunkerweb-createservice3.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice3.avif)

Dans cette étape, vous pouvez restreindre les méthodes HTTP, et augmenter la body size maximale (taille des pièces jointes uploadées).
Vous pouvez également restreindre certaines version TLS pour augmenter la sécurité.

## Étape 4 : HTTP - Headers

![bunkerweb-createservice4.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice4.avif)

Dans cette étape, vous pouvez modifier les paramètres liés aux headers HTTP. Personnellement je ne modifie rien dans celle-ci.
Vous pouvez également activer « USE_CORS » pour restreindre l’accès aux ressources de votre site par d’autres (cookie côté navigateur).

## Étape 5 : Security - Bad behavior

![bunkerweb-createservice5.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice5.avif)

Dans cette étape, vous pouvez configurer les sanctions suite à des mauvais comportements comme par exemple quand on bot va plusieurs fois sur votre site et obtiens beaucoup de fois une erreur 403 (forbidden). Cela peut supposer qu’il est entrain de bruteforce et par conséquent il est judicieux de le bannir.

## Étape 6 : Security - Blacklisting

![bunkerweb-createservice6.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice6.avif)

Dans cette étape, vous pouvez définir les paramètres de blacklist. Les valeurs par défaut font références à des bots connus pour fouiller les sites internets. Ils obtiendront une erreur 403 quand ils accèderont à votre service.

## Étape 7 : Security - Limiting

![bunkerweb-createservice7.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice7.avif)

Dans cette étape, vous pouvez configurer les rate limit HTTP. Cela permet d’éviter par exemple les bruteforces.

## Étape 8 : Security - Antibot

![bunkerweb-createservice8.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice8.avif)

Dans cette étape, vous pouvez configurer un mode antibot. Un captcha etc et plein de services différents.

## Étape 9 : Security - Auth basic

![bunkerweb-createservice9.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice9.avif)

Dans cette étape, vous pouvez configurer une authentification basique par HTTP. C’est un mot de passe simple.

## Étape 10 : Security - Country

![bunkerweb-createservice10.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice10.avif)

Dans cette étape, vous pouvez configurer des restrictions d’accès à votre site internet par pays. Nous pouvons par exemple empêcher les villains hackers russes et nord coréens d’accéder à notre maison connectée !

## Étape 11 : Security - ModSecurity

![bunkerweb-createservice11.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice11.avif)

Dans cette étape, vous pouvez configurer les règles ModSecurity.

Une fois tous les paramètres configurés, vous pouvez cliquer sur « Save ». En arrière-plan, BunkerWeb commencera le déploiement, cela devrait prendre une minute !

Et voici ! Votre service est déployé !

# Conclusion

**N'hésitez pas à me [faire un don](https://creeper.fr/about#me-faire-un-don) pour me remercier et me soutenir dans le maintien de cette documentation face aux mises à jour furtives de Debian.**

##### [Comment mettre en place un reverse proxy en toute sécurité avec l’aide d’un WAF (BunkerWeb) ?](https://creeper.fr/bunkerweb) by [Tristan BRINGUIER](https://creeper.fr) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)