---
layout: post
title: Mettre en place un reverse-proxy sécurisé grâce au WAF BunkerWeb
description: Cette documentation guide pas à pas l’auto-hébergement d’un reverse-proxy robuste en s’appuyant sur BunkerWeb, un WAF open-source français..
summary: Cette documentation explique comment sécuriser ses applications auto-hébergées en déployant BunkerWeb, un WAF open-source français.
tags: [bunkerweb, waf, nginx, selfhosting, reverse-proxy]
permalink: /bunkerweb/
---

## Introduction

**Depuis que je peux héberger toutes sortes d’applications**, **[accessibles via des adresses IPv4 publiques](https://creeper.fr/wireguardl)**, **la question de leur sécurité m’est devenue centrale**.

**Beaucoup se tournent vers** **[NGINX](https://nginx.org/)** — parfois accompagné d’**interfaces conviviales** **comme** **[NGINX Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager)** — ou vers d’**autres reverse proxies** tels que **[Caddy](https://github.com/caddyserver/caddy)** ou **[HAProxy](https://github.com/haproxy/haproxy)**. Pourtant, **ces solutions restent *[peu sécurisées](https://www.reddit.com/r/selfhosted/comments/176znvu/security_of_sites_behind_reverse_proxy/) par défaut***.

**Un certificat** **TLS/SSL** **assure** certes **le chiffrement des échanges**, **empêchant l’interception des données** sensibles (***sauf en cas d’attaque [MITM](https://fr.wikipedia.org/wiki/Attaque_de_l%27homme_du_milieu)***), **mais la sécurité ne s’arrête pas là** : **de nombreux** autres **aspects** **doivent être pris en compte** !

Il faut notamment **se prémunir contre les exploits applicatifs**, par exemple (*liste non exhaustive*) :

- les injections **SQL** ;
- le **cross-site scripting** ;
- l’**élévation de privilèges**.

**Un reverse-proxy se contente de relayer le trafic** ; **s’il n’intègre pas de protections**, **il transmettra l’exploit** sans sourciller.

La **généralisation de l’hébergement** via des **conteneurs** **Docker** **offre** un **certain niveau d’isolation** au niveau du **noyau Linux**, **mais une application compromise** **reste une porte d’entrée** potentielle **pour la fuite de données**.

**Il existe aussi des WAF grand public** et **professionnels**, comme **Cloudflare**, **qui proposent gratuitement** de **nombreuses fonctionnalités**. ***Malheureusement**, **ces solutions sont souvent mal déployées** (par ex. : non-restriction des IP à [**celles de Cloudflare**](https://www.cloudflare.com/ips/)) et **soulèvent des** [**questions éthiques**](https://0xacab.org/dCF/deCloudflare/-/blob/master/readme/fr.md) : confier son trafic à une société américaine, c’est accepter un intermédiaire puissant, ce qui, dans le contexte politique actuel, peut prêter à débat.*

**Toutes ces réflexions m’ont conduit à chercher un WAF** **simple d’utilisation et souverain 🇫🇷**, **c’est ainsi que j’ai découvert** **[BunkerWeb](https://bunkerweb.io)** !


## Présentation de BunkerWeb

**[BunkerWeb](https://bunkerweb.io)** est un **pare-feu d’applications Web** (**[Web Application Firewall](https://fr.wikipedia.org/wiki/Web_application_firewall)**) **open-source** de **nouvelle génération** qui fonctionne comme un [**reverse-proxy**](https://fr.wikipedia.org/wiki/Proxy_inverse) **complet** **basé** **sur** **NGINX**. Il est **développé** et **maintenu** par **Bunkerity**, **entreprise française** spécialisée en cybersécurité, ce qui inscrit la solution dans une **démarche** de **souveraineté numérique**. Publié **sous licence** **AGPL v3**, son **code** reste **entièrement** **auditable** et **modifiable**, **garantissant** à chacun la maîtrise de ses briques de **sécurité** et de leur évolution.

**Conçu pour la souveraineté** jusqu’au bout, BunkerWeb est totalement **auto-hébergeable** : il se déploie **[on-premises](https://en.wikipedia.org/wiki/On-premises_software)** sur un **Linux** ou via **Docker**. **Sans aucune dépendance** **à** un **SaaS externe**, toutes les règles, journaux et certificats TLS **demeurent sous votre contrôle**, répondant aux **exigences** **les plus strictes** en matière de **résidence** et de **conformité des données.**

**Par défaut**, BunkerWeb **protège** vos **services** avec une approche secure by default : **intégration** **de** **[ModSecurity](https://github.com/owasp-modsecurity/ModSecurity)** **et** **de** l’[**OWASP CRS**](https://github.com/coreruleset/coreruleset), **durcissement TLS**, **bannissement automatique** des **comportements anormaux**, **défis pour les robots**, **rate limiting**, **blacklists IP** **et bien plus**. Un système de **plugins** **permet** d’**étendre** **les capacités** (PHP, notifications, etc.), tandis que l’**interface Web** **simplifie** **la gestion** depuis n’importe où.

**Après avoir examiné l’ensemble des critères évoqués plus haut** et **échangé** **avec plusieurs développeurs** du projet lors du [**FIC**](https://europe.forum-incyber.com/), j’ai **décidé de déployer** **BunkerWeb au sein de mon** **homelab**. Quelques mois plus tard, **le bilan est sans appel** : **j’en suis pleinement satisfait**.

**Dans cet article**, **nous verrons pas à pas comment installer et configurer BunkerWeb**.

## Pré-requis

> **BunkerWeb peut s’exécuter sur n’importe quel environnement Docker.**  
> **Prévoyez** au **minimum** **2 vCPU** et **4 Go de RAM** pour un **usage standard** ; dans des **contextes plus exigeants**, **préférez** plutôt **4 vCPU** et **16 Go de RAM**.

#### Pourquoi autant de ressources ?

- **La mémoire est mise à contribution** parce qu’un **processus ModSecurity dédié** est **lancé pour chaque sous-domaine** — une option que l’**on peut désactiver** sur les **machines disposant de peu de RAM**, comme nous le verrons plus loin.  
- **La charge CPU, quant à elle**, provient surtout du **chiffrement avancé** et des **optimisations à la volée** (compression **[GZip](https://fr.wikipedia.org/wiki/Gzip)** ou **[Brotli](https://fr.wikipedia.org/wiki/Brotli)**), qui **allègent le poids des fichiers** **transmis aux clients** au détriment d’un surcroît de calcul.

#### Ports réseau à autoriser

| Port | Protocole | Rôle |
|------|-----------|------|
| **80**  | TCP | HTTP |
| **443** | TCP | HTTPS |
| **443** | UDP | HTTP/3 🚀 |

> **Pour le trafic réseau**, **pensez à autoriser les ports** **80/TCP**, **443/TCP** et **443/UDP**.  
> Le port **443 en UDP est indispensable pour la prise en charge de HTTP/3 : le futur 🚀 est à nos portes !**

#### Règles DNS

**Assurez-vous également** de **créer un enregistrement** **DNS** **pour l’interface d’administration Web** ; disposer de cette entrée **dès le départ** permet d’**effectuer la configuration initiale** de BunkerWeb **directement depuis l’URL** correspondante.  
De même, **chaque sous-domaine que vous protégerez avec BunkerWeb devra auparavant avoir son enregistrement DNS approprié** !!

**Une fois ces prérequis validés, passons au déploiement de notre WAF !**

## Déploiement de BunkerWeb avec Docker Compose

**Commencez par créer un fichier** **`compose.yaml`**, **puis** **copiez-y** **le bloc de configuration ci-dessous** :

```yaml
###############################################################################
##                          BunkerWeb – Docker Compose                         #
## Ce fichier déploie BunkerWeb (reverse-proxy + WAF), son ordonnanceur,       #
## l’interface Web d’administration et une base MariaDB pour le stockage       #
## interne. Les réseaux et volumes sont créés automatiquement.                 #
##                                                                             #
## → AVANT DE PASSER EN PROD :                                                 #
##   - Changez tous les mots de passe « motdepasseachanger ».                  #
##   - Révisez la liste d’IP autorisées (API_WHITELIST_IP).                    #
##   - Mettez vos propres certificats TLS ou configurez Let’s Encrypt.         #
###############################################################################

################################ Variables globales ############################
## Regroupées sous une ancre YAML (&bw-env) pour pouvoir être ré-utilisées
## (« merge key » <<) dans les différents services.
x-bw-env: &bw-env
  ## Liste d’IP autorisées à appeler l’API interne de BunkerWeb.
  ## Format : réseaux CIDR séparés par des espaces.
  API_WHITELIST_IP: "127.0.0.0/8 10.20.30.0/24"

  ## Chaîne de connexion à la base MariaDB (SQLAlchemy).
  ## ➜ Changez le mot de passe **et** éventuellement le nom de la base.
  ##    mariadb+pymysql://utilisateur:motdepasse@hôte:port/base
  DATABASE_URI: "mariadb+pymysql://bunkerweb:motdepasseachanger@bw-db:3306/db"

###############################################################################
##                                   Services                                ##
###############################################################################
services:
  ###########################################################################
  ## 1. Reverse-proxy / WAF                                                ##
  ###########################################################################
  bunkerweb:
    image: bunkerity/bunkerweb:latest      ## Utilise la dernière image stable
    ## ── Ports exposés ──────────────────────────────────────────────────────
    ports:
      - "80:8080/tcp"    ## HTTP  vers port interne 8080
      - "443:8443/tcp"   ## HTTPS vers port interne 8443
      - "443:8443/udp"   ## HTTP/3 (QUIC) sur le même port 8443 en UDP
    ## ── Variables d’environnement ─────────────────────────────────────────
    environment:
      <<: *bw-env                       ## Fusionne les variables communes
    ## ── Redémarrage automatique ───────────────────────────────────────────
    restart: unless-stopped             ## Relance sauf si vous l’arrêtez manuellement
    ## ── Réseau ────────────────────────────────────────────────────────────
    networks:
      - bunker                          ## Place le conteneur sur le réseau « bunker »
    ## ── Logs ──────────────────────────────────────────────────────────────
    logging:
      driver: json-file
      options:
        max-size: "10m"                 ## Rotation : 10 Mo par fichier
        max-file: "5"                   ## Garde 5 fichiers (≈ 50 Mo max)

  ###########################################################################
  ## 2. Ordonnanceur (scheduler)                                           ##
  ###########################################################################
  bw-scheduler:
    image: bunkerity/bunkerweb-scheduler:latest
    environment:
      <<: *bw-env
      BUNKERWEB_INSTANCES: "bunkerweb"   ## Nom du service à piloter
      SERVER_NAME: ""                    ## Laissez vide si pas de domaine dédié
      MULTISITE: "yes"                   ## Active la gestion multi-hôtes
      UI_HOST: "http://bw-ui:7000"       ## Adresse de l’interface UI
    volumes:
      - bw-data:/data                    ## Monte les données persistantes (policies, etc.)
    restart: unless-stopped
    networks:
      - bunker                           ## Même réseau que bunkerweb
      - bunker-db                        ## Accès direct à la base

  ###########################################################################
  ## 3. Interface Web d’administration                                     ##
  ###########################################################################
  bw-ui:
    image: bunkerity/bunkerweb-ui:latest
    environment:
      <<: *bw-env
    restart: unless-stopped
    networks:
      - bunker                           ## Doit voir le proxy
      - bunker-db                        ## Doit voir MariaDB

  ###########################################################################
  ## 4. Base de données MariaDB                                             ##
  ###########################################################################
  bw-db:
    image: mariadb:11                    ## Version 11.x LTS
    environment:
      ## Mot de passe root généré automatiquement (non enregistré dans Compose)
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"

      ## Création automatique de la base et de l’utilisateur applicatif
      MYSQL_DATABASE: "db"
      MYSQL_USER: "bunkerweb"

      ## ☠️ À CHANGER ABSOLUMENT AVANT PROD !
      ##   ➜ Pensez aussi à mettre à jour DATABASE_URI plus haut.
      MYSQL_PASSWORD: "motdepasseachanger"
    volumes:
      - bw-dbdata:/var/lib/mysql         ## Persistance des données SQL
    restart: unless-stopped
    networks:
      - bunker-db                        ## Isolé du reste pour sécurité

###############################################################################
##                                  Réseaux                                  ##
###############################################################################
networks:
  ## Réseau frontal (reverse-proxy, scheduler, UI, etc.)
  bunker:
    name: bunker
    ipam:                                ## Attribution d’adresse statique possible
      driver: default
      config:
        - subnet: 10.20.30.0/24          ## Réseau identique à celui autorisé dans BunkerWeb

  ## Réseau backend (UI & scheduler ↔ MariaDB). Non exposé au proxy.
  bunker-db:
    name: bunker-db

###############################################################################
##                                  Volumes                                  ##
###############################################################################
volumes:
  ## Policies, certificats, listes IP, etc.
  bw-data:
  ## Données SQL de MariaDB
  bw-dbdata:
```

**N’oubliez pas de changer le mot de passe** `"motdepasseachanger"` **par un autre aléatoire** 🔐 ! **Vous pouvez également le faire avec la commande suivante** (qui génère un mot de passe aléatoire de 32 caractères et remplace compose.yaml à votre place) :

```shell
sed -i -e "s|motdepasseachanger|$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c32)|g" -e '/^[[:space:]]*#/d' -e 's/[[:space:]]*#.*//' -e '/^[[:space:]]*$/d' compose.yaml
```

**Une fois le fichier compose.yaml prêt**, il vous suffit de **`docker compose up -d`** **puis passez à la première configuration via l’interface web** !

**Le premier démarrage peut prendre un certain temps** ⏰, vous pouvez **observer l’avancement** via les **logs** avec la commande suivante : 

**`docker compose logs --follow`**

## Premier démarrage via l’interface web

1. **Rendez vous sur `https://url-de-votre-bunker.web/setup` afin de retrouver la page de démarrage suivante :**

   ![bunkerweb-setup1.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup1.avif)

   **Dans un premier temps**, vous devez **renseigner** les **propriétés** du **compte administrateur**.
2. **Ensuite, vous devez renseigner le hostname public de votre instance BunkerWeb.**  
   ![bunkerweb-setup2.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup2.avif)


   > ⚠️ **Attention !!** Il ne faut **surtout pas toucher** à **UI Host** et **UI URL** !!

**En ce qui en est de la gestion des certificats TLS/SSL**, **l’implémentation de Let’s Encrypt** est **très simple d’utilisation** !  
Il vous **suffit de cocher** **« Auto Let’s Encrypt »** pour que cela soit **géré de manière automatique**, et de **mentionner un mail** pour **recevoir les informations Let’s Encrypt**.

**Vous avez aussi la possibilité de demander des certificats TLS/SSL via** **DNS**, **permettant** ainsi donc **l’usage de** **Wildcards** (`*.votredomaine.tld`).  
Pour cela :

- **Sélectionnez** comme **Challenge Type** : `dns`  
- **Choisissez** votre **DNS Provider**  
- **Renseignez** la **clé d’API** adéquate

3. **Une fois toutes les informations renseignées, BunkerWeb propose un récapitulatif des paramètres renseignés précédemment.**  
   Vous pouvez **valider** et **lancer l’installation**.

   ![bunkerweb-setup3.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup3.avif)
   
   **Après avoir patienté** le temps de **la** **mise en place** de BunkerWeb, vous devriez être **redirigé sur la page de** **login**. **Vous pouvez vous y connecter**.

   ![bunkerweb-setup4.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-setup4.avif)

## Présentation de l’interface web et paramétrage rapide

**Bienvenue sur l’interface web de** **BunkerWeb** !

![bunkerweb-interface1.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-interface1.avif)

**Sur la page d’accueil**, vous **retrouverez** quelques **statistiques** **essentielles** liées à **votre** **instance**.  
**Dans la barre latérale**, à gauche, se trouvent les **menus suivants** :

- **Home** : ***Page d’accueil***
- **Instances** : ***Uniquement utile pour un cluster**, c’est dans cette rubrique que sont renseignées les **différentes instances composant le cluster***
- **Global Config** : ***Gérer la configuration générale** **et commune à tous les services***
- **Services** : ***Gérer la configuration de chaque VirtualHost** / **service***
- **Configs** : ***Gérer les configurations NGINX avancées***
- **Plugins** : ***Gérer les modules supplémentaires***
- **Cache** : ***Gérer les fichiers mis en cache***
- **Reports** : ***Consulter les alertes et blocages***
- **Bans** : ***Consulter les bannissements***
- **Jobs** : ***Gérer les tâches planifiées***
- **Logs** : ***Consulter les fichiers de journalisation***

**Les catégories principales** **que j’utilise régulièrement** sont **Global Config**, **Services** et **Bans** / **Report**.

**Nous allons maintenant passer en revue** **quelques paramètres** **pratiques**, pour ce faire, **rendez-vous dans la rubrique** « **Global Config** »

![bunkerweb-interface2.avif](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-interface2.avif)

**En haut à gauche**, le **menu déroulant** vous **permet de choisir la configuration de chaque plug-in** ; **en haut à droite**, le **bouton** **Save** enregistre vos changements.
**Ci-dessous**, vous trouverez **les principaux réglages** sur mon **instance personnelle** :

#### ⚙️ Général

* `LISTEN_STREAM` : **false** – *désactive la fonctionnalité Stream de NGINX (permettant de forward les ports).*
* `USE_TCP` : **false**
* `USE_UDP` : **false**

#### 🗜️ Brotli

* `USE_BROTLI` : **true** – *active la compression Brotli pour des transferts encore plus légers (vous pouvez ensuite affiner niveau et types MIME).*

#### 📦 Cache client

* `USE_CLIENT_CACHE` : **true** – *autorise le cache côté navigateur, soulageant ainsi votre serveur.*

#### 🗜️ Gzip

* `USE_GZIP` : **true** – *démarre la compression Gzip, largement reconnue ; ajustez ensuite les paramètres selon vos besoins.*

#### 🔐 Let’s Encrypt

* `AUTO_LETS_ENCRYPT` : **true** – *préremplit les champs Let’s Encrypt lors de la création d’un service.*
* `EMAIL_LETS_ENCRYPT` : **mail@votredomaine.tld**


#### 🛡️ ModSecurity

* `USE_MODSECURITY_GLOBAL_CRS` : **true** – *⚠️⚠️ à envisager seulement si votre machine dispose de peu de RAM⚠️⚠️.*

#### 🔄 Reverse Proxy

* `REVERSE_PROXY_INTERCEPT_ERRORS` : **false** – *permet d’afficher l’erreur native du service (utile, par exemple, avec Guacamole).*

#### 🔒 SSL

* `REDIRECT_HTTP_TO_HTTPS` : **true** – *force la redirection vers HTTPS.*
* `SSL_PROTOCOLS` : **TLSv1.3** – *limite les échanges au protocole le plus récent.*

**Passons à présent au déploiement d’un service.**

## Déployer un service pas à pas

> **Prérequis :** **assurez-vous d’avoir créé au préalable l’enregistrement DNS du service** ; il servira à l’**émission automatique du certificat** **Let’s Encrypt**.

Ouvrez la section **Services** puis cliquez sur **Create new service**. Suivez ensuite les étapes décrites ci-après.

### 1 | Web service – *Front service*

![Capture : création d’un service — étape 1](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice1.avif)

* **`SERVER_NAME`** : nom(s) de domaine à protéger.
* **Let’s Encrypt** : si **`AUTO_LETS_ENCRYPT`** n’est *pas* à `true`, renseignez les champs manuellement.
* **Template** : choisissez un profil de sécurité (*low*, *medium*, *high*) adapté à la criticité de l’application.

Ces réglages concernent la *face publique* du reverse-proxy exposée sur Internet.

### 2 | Web service – *Upstream server*

![Capture : création d’un service — étape 2](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice2.avif)

* **`REVERSE_PROXY_HOST`** : URL interne du service (incluant le schéma `http://` ou `https://`).
* **`REVERSE_PROXY_WS`** : activez-le pour la prise en charge des WebSockets.

### 3 | HTTP – *General*

![Capture : création d’un service — étape 3](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice3.avif)

| Variable              | Rôle                            | Suggestion                                                       |
| --------------------- | ------------------------------- | ---------------------------------------------------------------- |
| **`ALLOWED_METHODS`** | Méthodes HTTP autorisées        | Conservez les valeurs du template, sauf besoin spécifique.       |
| **`MAX_CLIENT_SIZE`** | Taille max. du corps de requête | Ex. `1024m` pour autoriser des uploads massifs.                  |
| **`SSL_PROTOCOLS`**   | Versions TLS admises            | Restreignez à `TLSv1.3` si vous exigez le niveau le plus strict. |

### 4 | HTTP – *Headers*

![Capture : création d’un service — étape 4](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice4.avif)

Vous pouvez ici :

* ajouter ou supprimer des en-têtes personnalisés ;
* activer **`USE_CORS`** pour contrôler le partage de ressources entre sites (pratique pour limiter le vol de cookies).

> *Conseil :* les valeurs par défaut conviennent à la plupart des cas.

### 5 | Security – *Bad behavior*

![Capture : création d’un service — étape 5](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice5.avif)

Le module **Bad behavior** bannit les clients générant trop d’erreurs.

| Variable                        | Par défaut                    | Fonction                             |
| ------------------------------- | ----------------------------- | ------------------------------------ |
| **`BAD_BEHAVIOR_STATUS_CODES`** | `400 401 403 404 405 429 444` | Codes suivis.                        |
| **`BAD_BEHAVIOR_THRESHOLD`**    | `10`                          | Nombre d’erreurs déclenchant le ban. |
| **`BAD_BEHAVIOR_COUNT_TIME`**   | `60 s`                        | Fenêtre de comptage.                 |
| **`BAD_BEHAVIOR_BAN_TIME`**     | `86400 s` (24 h)              | Durée du ban.                        |

Les valeurs par défaut sont généralement suffisantes.

### 6 | Security – *Blacklisting*

![Capture : création d’un service — étape 6](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice6.avif)

Activez **`USE_BLACKLIST`** pour bloquer immédiatement les IP ou user-agents référencés dans les listes internes ou personnelles. Par défaut, la configuration protège déjà contre les robots les plus agressifs.

### 7 | Security – *Limiting*

![Capture : création d’un service — étape 7](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice7.avif)

* **`USE_LIMIT_CONN`** : limite le nombre de connexions simultanées.
* **`USE_LIMIT_REQ`** : plafonne le débit de requêtes (HTTP 429 en cas d’excès).

> Ajustez les quotas uniquement si un service légitime se voit bloqué.

### 8 | Security – *Antibot*

![Capture : création d’un service — étape 8](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice8.avif)

* **`USE_ANTIBOT`** : active la protection.
* **`ANTIBOT_MODE`** : `captcha` (résolution manuelle) ou `javascript` (tests invisibles).
* **`ANTIBOT_PROVIDER`** : *reCAPTCHA*, *hCaptcha*, *Turnstile*, etc. (clé site & secret requis).

Si jamais vous avez besoin de rajouter un captcha, choisissez `javascript` tant que possible pour préserver l’ergonomie. Si besoin de sécurité supplémentaire. puis passez en `captcha` sur les pages les plus sensibles.

### 9 | Security – *Auth basic*

![Capture : création d’un service — étape 9](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice9.avif)

Placez un verrou HTTP Basic en activant **`USE_AUTH_BASIC`** puis :

* renseignez `login:password` (ou hashés) dans **`AUTH_BASIC_LIST`**,
* ou référencez un fichier `.htpasswd` avec **`AUTH_BASIC_FILE`**.

### 10 | Security – *Country*

![Capture : création d’un service — étape 10](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice10.avif)

* **`BLACKLIST_COUNTRY`** : bloque la liste de pays indiqués (`RU KP` par ex.).
* **`WHITELIST_COUNTRY`** : autorise *uniquement* les pays listés (`FR BE`, etc.).

Toute requête provenant d’un pays exclu reçoit un **403 Forbidden**.

### 11 | Security – *ModSecurity*

![Capture : création d’un service — étape 11](https://forevercdn.creeper.fr/img/bunkerdoc/bunkerweb-createservice11.avif)

ModSecurity analyse chaque requête / réponse à l’aide du Core Rule Set (OWASP). Conservez les réglages par défaut, puis excluez au besoin des règles via la rubrique **Custom configuration**.

### 12 | Finaliser le déploiement

Cliquez sur **Save** : BunkerWeb lance immédiatement le déploiement en arrière-plan (**patientez ≈ 1 min**).
**Votre service est maintenant protégé et accessible à l’extérieur !**

## Conclusion

**Et voilà**, **vous avez maintenant un reverse-proxy sécurisé pour toutes vos applications !**

J’améliorerai cette documentation au fil du temps en fonction des situations et problèmes que je rencontrerais à l’avenir.

#### Si vous avez apprécié cette documentation…

**N'hésitez pas à me [faire un don](https://creeper.fr/about#me-faire-un-don) pour me remercier et me soutenir dans le maintien de cette documentation et plus généralement de ce blog.**

###### [Mettre en place un reverse-proxy sécurisé grâce au WAF BunkerWeb](https://creeper.fr/bunkerweb) by [Tristan BRINGUIER](https://creeper.fr) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

#### Implémentations futures :

- Ajout d’exceptions ModSecurity
- Ajout de cas par cas applications Authentik