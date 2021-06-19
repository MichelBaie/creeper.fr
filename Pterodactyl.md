# Installer Pterodactyl avec les IP Failover OVH

C'est génial !
Cela fait bientôt plus d'1 an que j'essaie de faire marcher [Pterodactyl](https://pterodactyl.io) avec mes IP failover chez moi, et je restais bloqué à une bête erreur de Traffic.
Grâce à [@Aven](https://github.com/Aven678) et [@DrKnaw](https://github.com/DrKnaw) et leurs investigations, on a réussi à contourner ce blocage bête et à réussir à avoir une solution stable.

Ducoup aujourd'hui on se retrouve pour un petit tuto afin d'installer le panel Pterodactyl sur une VM (qui possède une IP failover si besoin) afin de pouvoir gérer facilement ses serveurs de jeu et héberger ses amis.

## 1 - Prérequis

* Un nom de domaine (de préférence passé sur Cloudflare car c'est cool)
* Ubuntu 20.04 (c'est mieux)

Connectez-vous à votre VPS en SSH, et on va le mettre à jour pour bien commencer :

```
apt update && apt full-upgrade -y
```

Ensuite on va appliquer notre petit "patch" réseau en modifiant notre fichier /etc/hosts

```
nano /etc/hosts
```

![Fichier Host Classique](./img/pterodactyl1.png)

Et vous pouvez ensuite rajouter la ligne suivante :

```
127.0.0.1       panel.monpanel.fr
```

En n'oubliant pas de remplacer panel.monpanel.fr par le nom de domaine de notre panel.
Il sera également de créer une règle de en prenant pour exemple celle ci-dessous :

![N'oubliez pas de remplacer les valeurs par les vôtres !!](./img/pterodactyl2.png)



Une fois tout ceci effectué, on devrais avoir une base solide.

Je précise que ce tutoriel est **basé sur [la documentation officielle de Pterodactyl](https://pterodactyl.io/panel/1.0/getting_started.html)** qui est susceptible **d'être modifiée dans le futu**r. A l'heure où j'écris cette documentation, tout fonctionne, cependant, si dans le futur des dysfonctionnements apparaissent, j'essaierais de les corriger.

De plus, il est préférable que l'**IP failover soit déjà montée** pour que tout fonctionne dans le futur (voir l'ancienne doc : [ici](https://michelbaie.github.io/Tutos/OVH))

## 2 - Téléchargeons la base de notre Pterodactyl

On va déjà installer des dépendances de base en vrac :

```
apt install sudo bash curl wget gnupg software-properties-common apt-transport-https
```

A l'heure actuelle, la nouvelle version de PHP 8.0, mais vous pouvez encore être sur du PHP7, pour vérifier ceci on va voir les paquets PHP disponibles :

```
apt list | grep php
```

![Les paquets disponibles à l'heure actuelle](./img/pterodactyl3.png)

Si on remonte un peu, on peut voir que sur l'exemple ci-dessus, la version encore disponible est **PHP 7.4** on va devoir la **garder pour plus tard**

On peut ensuite installer les dépendances nécessaires à Pterodactyl :

```bash
apt -y install php php-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
```

Et supprimer apache2 (car il s'installe tout seul c'est chiant) :

```
apt-get purge apache* -y
```

Une fois que tout est propre sur notre machine, on peut continuer en installant composer (pour installer notre environnement php) :

```bash
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
```

On peut ensuite créer nos fichiers :

```bash
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
```

Et on télécharge notre panel :

```bash
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
```

## 3 - Créer la base de données MySQL (MariaDB)

A partir d'ici, nous allons avoir besoin d'une base de données MySQL pour le bon fonctionnement de notre Pterodactyl.
Par défaut, MariaDB (le serveur MySQL) est installé avec les dépendances qu'on à téléchargé au dessus, vous ne devriez donc pas avoir de problèmes de dépendances.

Connectez-vous à notre mysql :

```bash
mysql -u root
```

Puis créez un compte utilisateur :

```sql
USE mysql;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'somePassword';
```

N'oubliez pas de changer la valeur `somePassword` par un mot de passe très sécurisé (surtout que les IP OVH sont [victimes de beaucoup d'attaques](https://blog.ovh.com/fr/blog/rapport-attaques-ddos-observees-par-ovh-en-2017/))

On peut ensuite créer une base de données et donner les permissions à notre utilisateur :

```sql
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
```

Et appliquer toutes nos modifications :

```sql
FLUSH PRIVILEGES;
```

## 4 - Retournons à notre interface Web

Nous pouvons ensuite continuer notre installation en installant les dépendances composer :

```bash
cp .env.example .env
composer install --no-dev --optimize-autoloader
```

![On autorise le root](./img/pterodactyl4.png)

N'oubliez pas de dire **yes** pour faire tourner en tant que root, c'est déconseillé mais bon on va faire avec.

Et on génère les clés de notre interface :

```bash
php artisan key:generate --force
```

**Si jamais vous allez bouger votre serveur, gardez une copie de votre fichier .env (/var/www/pterodactyl/.env) car il contiens les clés de chiffrement de votre base de données. Sans celle-ci, toutes les données seront incompréhensible !**

## 5 - Les setups interactifs

On va commencer la petite partie interactive de ce tutoriel. Je vais mettre des captures d'écrans à chaque propositions.

Lançons le premier setup :

```bash
php artisan p:environment:setup
```

![](./img/pterodactyl5.png)

Ici, il nous demande un email qui sera affiché comme le créateur des eggs exporté depuis cette installation pterodactyl. Un egg est un petit script d'installation de serveur de jeu, si jamais vous en développez depuis votre instance, il est préférable de donner un email sympa. Sinon ce n'est pas important, vous ne recevrez jamais d'email avec cette option.

![Il nous demande l'URL de notre Pterodactyl](./img/pterodactyl6.png)

Ici, on lui donne notre URL que l'on utilisera dans notre navigateur web. Il est nécessaire de préciser le https:// comme indiqué dans l'image au dessus, car nous allons ensuite générer les certificats SSL. Il n'est pas non plus nécessaire de rajouter un / à la fin.