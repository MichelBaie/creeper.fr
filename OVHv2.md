# Avoir des IP FO chez soi (grâce à OVH et quelques tunnels)

Pour mettre un peu de contexte, j'ai récupéré chez moi un serveur qui fait tourner pas mal de machines virtuelles. Bénéficiant de la fibre, je souhaite héberger des services pour la famille, des amis, et des personnes à qui je parle. 
Seulement, avec une seule IP (résidentielle), je suis très vite limité par mon nombre de ports mis à ma disposition, et je suis vite obligé de faire un choix sur quels services héberger, ou éteindre...
Mais heureusement qu'avec un peu de temps et d'argent, je peux désormais bénéficier d'IP dédiées à mes machines virtuelles. Ce sont des IP OVH (qui bénéficient de protection Anti-DDOS), qui sont localisées dans plusieurs pays du monde, et qui ne coûtent seulement 2€50 !
Ça a changé ma manière d'héberger chez moi, et je tenais à vous partager ma solution.

Je précise que je ne suis pas un expert réseau, pour certaines personnes cette technique peut sembler sale ou incomplète, mais pour mon utilité elle est parfaite.
De plus, ce tuto est une seconde version grâce à la contribution de beaucoup de personnes qui m'ont aidé à avoir un résultat très qualitatif et stable, ils sont mentionnés à la fin de cet article.

## 1 - Les pré-requis

* Un VPS OVH (C'est plus pratique, je ne ferais pas de support pour les autres hébergeurs)
* Des IP Failover (Elles coûtent 2€50 l'unité, une seule fois, et sont possédées jusqu'à l'expiration du VPS)
* Debian 11> ou Ubuntu 21> (Du moment qu'on a un kernel linux 5.10>, qui supporte nativement WireGuard)
* Un bon ping (C'est préférable pour la qualité de notre réseau)

Justifications :

* J'ai choisi OVH, car c'est l'un des seuls (ou le seul ?) hébergeur français à proposer des adresses IP à 2€50 à vie, ce qui peut réduire fortement nos coûts mensuels, car dans beaucoup d'autre hébergeurs on paie plus cher l'IP et on la paie par mois... De plus ils sont plûtot fiables et proposent un Anti-DDOS basique et gratuit !
* Pour le tunnel, nous allons utiliser Wireguard, un protocole VPN qui passe sur de l'UDP. Il est compatible avec énormément de plateformes, est extrêmement léger, très facile à déployer et beaucoup plus performant que ses concurrents, tout en restant chiffré. C'est un petit nouveau (qui commence à dater) qui viens tout juste d'arriver dans le domaine de l'open-source et qui as fait ses preuves chez moi ces deux dernières années.
* La qualité de l'interconnexion dépendra de votre réseau, Wireguard ne nécessite pas une bonne connexion internet, et ne réduira pas (ou très peu) votre débit. Cependant, vous devrez rajouter le ping entre vous , OVH et OVH , vous. Pour du jeu, le ping est critique.
* Debian 11> et Ubuntu 21> intègrent enfin Wireguard dans leurs kernels linux natifs en production, ce qui va réduire les commandes de construction qu'étaient présentes dans l'ancienne version du tutoriel. Cependant, il faut obligatoirement (si vous suivez à la lettre ce tutoriel) que vous utilisez le même OS que moi.

## 2 - Achetons notre VPS

J'ai donc fait le choix d'OVH, voici leur grille tarifaire (au 02/01/2022) :

| Édition            | Starter    | Value      | Essential  | Comfort  | Elite    |
| ------------------ | ---------- | ---------- | ---------- | -------- | -------- |
| Prix mensuel (TTC) | 3,60€      | 6€         | 12€        | 24€      | 33,12€   |
| Bande passante     | 100 Mbit/s | 250 Mbit/s | 500 Mbit/s | 1 Gbit/s | 2 Gbit/s |
| Stockage SSD       | 20 Go      | 40 Go      | 80 Go      | 160 Go   | 160 Go   |

Toutes ces offres peuvent supporter jusqu'à 16 IP Failovers (par VPS). Pour en avoir plus il faudra dépenser plus et souscrire un serveur dédié qui devrait avoir une meilleure protection Anti-DDOS !

Pendant que vous achetez le VPS, je vous conseille de choisir l'OS Debian 11. Il est conçu pour être stable et à jour. De plus, certaines choses dans la suite du Tuto peuvent varier en fonction de la distribution linux que vous choisissez. Si vous être un utilisateur averti, vous pouvez choisir votre préféré :heart_eyes:

Une fois que vous avez acheté votre VPS, prenez directement une IP Failover (Bare Metal Cloud --> IP --> Commander des IP additionnelles), et sélectionnez bien le bon VPS. Il vous sera donné un lien avec l'état de la commande. Quand vous aurez reçu le mail de confirmation comme quoi telle ip à été bien ajoutée à votre service, alors vous pourrez continuer.

Il est important d'avoir (au moins) une IP Failover de disponible pour la suite du tutoriel.

## 3 - Installons notre VPS

Connectez-vous en SSH à l'aide des identifiants qui vous ont été envoyés par email.

Commençons par une mise à jour de l'OS :

```bash
sudo su -
apt update
apt upgrade -y
reboot
```

Une fois le redémarrage terminé, installons les dépendances nécessaires :

```bash
sudo su -
apt install wireguard wireguard-tools resolvconf bash curl wget -y
```

Nous avons ici installé les paquets nécessaires au bon fonctionnement de notre tunnel WireGuard, mais il et maintenant nécessaire de créer une configuration basique à notre serveur.
Pour cela, j'ai choisi d'utiliser un [script maintenu par quelqu'un sur Github](https://github.com/angristan/wireguard-install) qui crée un tunnel et crée facilement des profils :

```bash
curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
./wireguard-install.sh
```

Une fois ceci fait il va lancer notre petit setup interactif :

```bash
Welcome to the WireGuard installer!
The git repository is available at: https://github.com/angristan/wireguard-install

I need to ask you a few questions before starting the setup.
You can leave the default options and just press enter if you are ok with them.

IPv4 or IPv6 public address: <ipvps>
```

```bash
Public interface: ens3
```

```bash
WireGuard interface name: wg0
```

```
Server's WireGuard IPv4: 10.66.66.1
```

```
Server's WireGuard IPv6: fd42:42:42::1
```

```
Server's WireGuard port [1-65535]: XXXXXX
```
Ne touchez pas aux premières options, elles sont très bien autogénérées et on risque de modifier plusieurs choses par la suite.

```
First DNS resolver to use for the clients: 176.103.130.130
Second DNS resolver to use for the clients (optional): 176.103.130.130
```

Utilisons les meilleurs DNS (chacun son avis) : ceux de [CloudFlare](https://1.1.1.1/) : `1.1.1.1, 1.0.0.1`

Une fois tout ce QCM de remplis, il va tout préparer et nous demandera ensuite le nom de notre tout premier client.

```bash
Client name: MaVM
```

Ici, pour lui donner un nom facile à reconnaitre je vais l'appeler **MaVM**, mais vous pouvez l'appeler comme vous souhaitez.

```bash
Client's WireGuard IPv4: 10.66.66.2
```

```
Client's WireGuard IPv6: fd42:42:42::2
```

Il nous demande ici une ip (qui sera incrémentée pour les futurs clients), on la retirera plus tard, laissez là comme elle est.

Une fois toute cette installation terminée, nous allons pouvoir nettoyer un peu ce que ce script à généré. Il est initialement conçu pour router tout le traffic de nos profils sur l'IP du VPS, ce qui n'est pas vraiment ce que nous souhaitons.

```bash
nano /etc/wireguard/wg0.conf
```

Puis remplacez les lignes actuelles de PostUp et PostDown par :

```
PostUp = ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ens3 -j MASQUERADE
```

Une fois ceci fait, nous allons également ajuste quelques réglages de notre réseau linux pour autoriser le passage des paquets un peu partout :

```bash
nano /etc/sysctl.conf
```

Puis rajoutez les lignes suivantes tout en haut du fichier :

```
net.ipv4.ip_forward=1
net.ipv4.conf.all.proxy_arp=1

```

Une fois ceci fait, nous pouvons appliquer avec : 

```
sysctl -p
```

## 4 - Fabriquons nos profils WireGuard

Le Script à déjà créé un premier profil (MaVM), mais il va maintenant falloir le pimper pour qu'il ai sa bonne IP Failover.
Je précise qu'à partir, d'ici ce sera la même chose pour n'importe que profil généré à l'aide du script.
Pour regénérer un autre profil : `bash wireguard-install.sh`, et suivez les instructions.

Adaptons déjà les paramètres du côté serveur :

```bash
nano /etc/wireguard/wg0.conf
```

```
### Client MaVM
[Peer]
PublicKey = jeSuiSuNeCléeVrAimeNtTrèsComPliquÉe==
PresharedKey = jeSuiSuNeCléepArtAgéEVrAimeNtTrèsComPliquÉe==
AllowedIPs = 10.66.66.2/32,fd42:42:42::2/128
```

Ce qui nous intéresse ici, ce sont les AllowedIPs, ce sont les addresses IP qui ont été attribuées pour le profil MaVM. Modifions celle-ci en retirant l'ip locale (10.66.66.2/32) et en rajoutant l'IP FO OVH (par exemple : 92.122.45.218) . Cela devrais nous donner ceci :

```
AllowedIPs = 92.122.45.218/32,fd42:42:42::2/128
```

Je précise que sur un VPS il est important de mettre un /32 à la fin de l'IP pour ne pas avoir de problèmes de routage.
Je préfère également conserver l'IPV6 (qui sera celle du VPS) pour avoir une navigation plus moderne sur le Web !

Une fois cette modification faite, nous pouvons sauvegarder puis effectuer la même du côté de notre client.
Dans notre dossier nous devrions avoir un `wg0-client-MaVM.conf`, modifions-le !

```
nano wg0-client-MaVM.conf
```

```
[Interface]
PrivateKey = jeSuiSuNeCléeVrAimeNtTrèsComPliquÉe==
Address = 10.66.66.2/32,fd42:42:42::3/128
DNS = 1.1.1.1,1.0.0.1

[Peer]
PublicKey = jeSuiSuNeCléeVrAimeNtTrèsComPliquÉe==
PresharedKey = jeSuiSuNeCléepArtAgéEVrAimeNtTrèsComPliquÉe==
Endpoint = 54.39.36.154:55563
AllowedIPs = 0.0.0.0/0,::/0
```

Ici également il faut remplacer à côté de Address, l'IP Locale par celle de la Failover (avec le /32 à la fin !). Cela devrais nous donner ceci :

```
Address = 92.122.45.218/32,fd42:42:42::3/128
```

Une fois ce profil modifié et nos deux configurations sauvegardées, je vous conseil (pour la première fois) de reboot le VPS.
Si ce n'est pas la première fois, un simple redémarrage du service wireguard suffira :

```bash
systemctl stop wg-quick@wg0
systemctl start wg-quick@wg0
```

Si après tout ça la commande `systemctl status wg-quick@wg0` ne vous donne pas d'erreur alors tout est prêt !

## 5 - Déployons nos profils WireGuard :rocket:

Et voici ! 

Notre profil est maintenant prêt à être déployé sur n'importe quelle plateforme (Windows, Linux, Android, MacOS, IOS, et plein d'autres !)

Je vais vous faire un petit exemple sur un linux :

```
# Installer Wireguard (en étant sur Ubuntu 21> ou Debian 11>) :
apt install wireguard wireguard-tools resolvconf

# Installer le profil Wireguard :
nano /etc/wireguard/wg0.conf
(puis coller le profil wireguard modifié à l'intérieur)

# Activer et lancer notre profil wireguard au démarrage :
systemctl enable wg-quick@wg0 --now

# Et voici ! Votre IP est maintenant montée sur cet appareil !
# Vous pouvez vérifier en faisant un
ip a 
# ou un
curl ifconfig.me
```

C'est vraiment très rapide et simple ! Et ça marche 🤩

## (6) - Conclusion & Remerciements

Et voici, vous avez maintenant (16) IP Failovers disponibles chez vous, protégées par OVH sur n'importe quel appareil !

Cette astuce m'as permise de franchir un grand pas dans l'auto-hébergement que ce soit dans des services pour moi ou pour les autres car elle m'offre la puissance d'avoir des VPS (grâce à un hyperviseur comme Proxmox ou ESXi) avec des IP dédiées à prix tout à fait réduit et avec un service de qualité similaire.

Ce tutoriel existe initialement depuis Juillet 2020, mais a été remasterisé récemment en Janvier 2022 avec beaucoup d'améliorations et de mises à jour.
Wireguard à enfin été merge dans le kernel linux stable et est encore plus simple à installer qu'avant.

Et ce tutoriel à également été amélioré par la communauté et les personnes qui utilisent actuellement cette solution chez-eux ou autre part.
Je tiens à remercier :

* [@Aven678](https://github.com/Aven678/) : Pour avoir simplifié énormément la gestion des IP's et la création de profils
* [@DrKnaw](https://github.com/DrKnaw) : Pour avoir patché des bugs liés à mon système qui n'était pas tout à fait fini à l'époque
* [Mael](https://github.com/maelmagnien) : Qui as entièrement est testé le tutoriel pour voir que tout fonctionne

Et plein d'autres personnes qui m'ont envoyé un message sur Discord pour m'aider à améliorer cette documentation ou me remercier.
De plus, il existe sur Github des scripts et interfaces Web qui simplifient ma documentation réalisés également par la communauté.

Merci d'avoir suivi ce tutoriel.