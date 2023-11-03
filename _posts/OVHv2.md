---
layout: post
title: Avoir des IPV4 chez soi, ou comment ouvrir son HomeLab à tous !
description: Comment j'ai réussi facilement à monter des IP Failover chez Moi !
summary: Quand on héberge chez soit, on peut-être très vite limité.... Mais pas avec plein d'ip FO !
tags: [tunnel,hostmyservers,hms,ipfailover,ipfo,wireguard]
---

J'ai **serveur** chez moi sur lequel j'ai installé **[ESXi](https://customerconnect.vmware.com/fr/web/vmware/evalcenter?p=free-esxi8)**, un **hyperviseur** qui me permet de **créer plein de machines virtuelles**. Dans ces machines virtuelles **j'héberge divers services** pour moi et pour d'autres.

Seulement, avec **une seule IP** (résidentielle), je suis **vite limité** par le **nombre de ports** à ma disposition et le **nombre de services** que je souhaite faire tourner dans les **meilleures conditions**.

J'ai donc donc cherché **un moyen d'avoir des IP chez moi**, **dédiées**, **protégées** par un **Anti-DDOS** et **peu cher**. Je n'avais jusqu'ici pas trouvé de résultat convenable, qui fonctionne bien, qui est modulaire, j'ai donc décidé d'en **créer un**. 

## 1.1 - Les différentes approches

Au cours de cette documentation, nous allons aborder différentes approches pour avoir des IP chez soi, ou comment publier son HomeLab.

Avec le contexte de pénurie d'IPV4 que nous vivons aujourd'hui, il est important de savoir économiser ces IPs qui se font rare, notamment en ne commandant pas massivement des adresses qui seront inutilisées, privant ainsi d'autres utilisateurs.

C'est pour cela que j'ai apporté des modifications à ma documentation, pour y intégrer, et proposer, des solutions alternatives qui fonctionnent différemment, mais qui correspondront peut-être mieux à certaines personnes.

Voici les différentes approches qui seront traitées dans cette documentation :

1. L'originale méthode permettant d'associer à n'importe quelle machine une adresse IP publique via un profil WireGuard dédié.
2. Une seconde méthode permettant de monter toutes les adresses sur une machine "Gateway" via un tunnel WireGuard qui les redistribuera par la suite aux autres machines du réseau local.
3. Une version minimaliste, seulement pour ceux qui souhaitent seulement cacher leur IP, sans forcément vouloir ouvrir les ports. On se servira du VPS comme un véritable serveur VPN où les clients peuvent communiquer entre eux.
4. Une approche "applicative" où nous installerons un Reverse Proxy (NginxProxyManager) sur le VPS pour gérer tout le traffic web de nos clients WireGuard

L'avantage étant que que approches 3 et 4 ne nécessitent pas d'adresses IP additionnelles, c'est économe (car pas de frais supplémentaires) et compatible presque tous les hébergeurs.

## 1.2 - Les choix de l'hébergeur

J'ai fait le choix de HostMyServers, un hébergeur français qui a quelques années d'expérience, car ils proposent des tarifs très intéressant au niveau du réseau et la qualité de service est correcte. Le premier VPS SSD suffit amplement pour avoir un traffic raisonnable (~300Mbps) dans le tunnel, et inclut une protection AntiDDOS basique qui protège des attaques simples. Leur support via le site est relativement réactif, mais je n'ai pas rencontré tant de problèmes que ça après plus d'une année chez eux.

#### **Voici la grille tarifaire d'HMS (VPS SSD NVME) :** 

| Modèle                               | SSD-1      | SSD-2      | SSD-4     | SSD-8    | SSD-12   | SSD-12'  |
| ------------------------------------ | ---------- | ---------- | --------- | -------- | -------- | -------- |
| *Prix mensuel sans engagement (TTC)* | 2,99€      | 5,99€      | 9,99€     | 19,99€   | 29,99€   | 39,99€   |
| *Bande passante (garantie)*          | 250 Mbit/s | 500 Mbit/s | 800Mbit/s | 1 Gbit/s | 2 Gbit/s | 3 Gbit/s |
| *vCore(s)*                           | 1          | 2          | 4         | 8        | 12       | 12       |
| *Mémoire RAM*                        | 2 Go       | 4 Go       | 8 Go      | 16 Go    | 24 Go    | 32 Go    |
| *Stockage SSD*                       | 20 Go      | 40 Go      | 60 Go     | 120 Go   | 160 Go   | 200 Go   |

Le gros plus avantage étant le tarif des adresses IP additionnelles ! Chez HMS, l'adresse IP additionnelle coûte 1,99€ TTC à Vie (tant que le VPS est renouvelé). Contrairement aux autres hébergeurs qui font payer mensuellement un supplément par IP.

**Pour commander une IP Additionnelle**, il faut qu'**une fois le VPS Livré**, vous vous rendez dans l'**Espace Client** (**Votre VPS → Configuration → Commander une Nouvelle IP**), une fois la commande passée, un **mail de confirmation** vous **sera envoyé**.

À l’heure où j’écris cette documentation **les débits ne semblent pas bridés côté VPS**. Le **débit indiqué** sur les offres commercialisées sont ceux **garantis**.

### 1.3 - Quelques justifications et informations variées

* **J'ai choisi [WireGuard](https://www.wireguard.com/)** pour notre **tunnel**, un **protocole VPN** qui utilise de **l'UDP**. Il est **compatible** avec **énormément de plateformes**, est **extrêmement léger**, très **facile à déployer** et beaucoup plus **performant** que ses concurrents, tout en restant **sécurisé**. C'est un petit **nouveau** qui viens d'arriver dans le domaine de l'**open-source** et qui as fait ses preuves chez moi ces deux dernières années.

![](https://img.creeper.fr/Kiba9/sinILeGU17.png/raw)

* **La qualité de l'interconnexion dépendra de votre réseau**, WireGuard **ne nécessite pas une bonne connexion internet**, et **ne réduira pas votre débit**. Cependant, vous devrez rajouter le **ping** entre vous → HMS et HMS → vous.
  Vous pouvez voir votre ping en pingant mon VPS : hms.creeper.fr
* **Ne commandez pas de manière abusive des adresses IPV4**, il n'y en a presque plus aujourd'hui.
* **WireGuard** est un **protocole** qui rajoute une couche de **chiffrement**, cela demande de la **puissance de calcul** supplémentaire pour le VPS.
  Si **vous souhaitez** avoir **250Mbps**, **1 coeur** devrait suffir
  Si **vous souhaitez** avoir **500Mbps**, je vous recommande **2 coeurs**
  Si **vous souhaitez** avoir **1Gbps+**, je vous recommande **4 cœurs** serait nécessaire au minimum.
  Le débit (10Gbps) est bien présent physiquement sur le VPS, mais le chiffrement du tunnel WireGuard sature rapidement le CPU du VPS.
  Le débit sera stable et qualitatif, mais le débit sera réduit en fonction du nombre moindres de coeurs.

## 1.4 - Pré-requis pour bien suivre cette documentation

Afin de suivre au mieux la documentation, il est requis d'avoir :

* Un VPS (idéalement HMS car c'est le plus intéressant selon moi)
* Debian 12 d'installé dessus (les commandes de cette documentation ont été testées et validées pour cette version)
* Une ou plusieurs adresses IP additionnelles (tout dépends si vous en avez besoin en fonction de l'approche que vous utiliserez)
* Un minimum de connaissances de Linux. (Je ne peux pas vous apprendre toutes les bases dans cette documentation sinon elle serait sans fin)

Une fois que tous ces pré-requis sont remplis, vous pouvez suivre la suite de cette documentation. Allons-y !

## 2.1 - Préparation du VPS

**Connectez-vous en SSH** à votre VPS via les **identifiants** qui vous ont été **transmis par mail** ou que vous avez rentré lors de la **première installation**.

**Récemment**, les images des VPS Debian **de HMS** **ont changé**, et utilisent désormais **netplan.io** comme **gestionnaire de réseau**.
Cela **compromettant la documentation**, il est **nécessaire** que nous **revenions à ifupdown**.

Je vous ai préparé un script qui est censé tout faire tout seul, et vous préviens quand vous pouvez continuer la documentation :

```bash
curl -sSL https://raw.githubusercontent.com/MichelBaie/creeper.fr/main/_scripts/preparevps.sh | sudo bash
```

Ignorez les erreurs, quand le script vous dis que c'est prêt, continuez la documentation !

## 2.2 - Installation du serveur Wireguard

Nous pouvons maintenant **installer notre serveur WireGuard**.
Pour cela, j'ai choisi d'utiliser un [script maintenu par quelqu'un sur GitHub](https://github.com/angristan/wireguard-install) qui **crée un tunnel** et génère facilement des profils :

```bash
wget https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
bash wireguard-install.sh
```

Une fois ceci fait il va lancer un **petit setup interactif** :

```bash
Welcome to the WireGuard installer!
The git repository is available at: https://github.com/angristan/wireguard-install

I need to ask you a few questions before starting the setup.
You can keep the default options and just press enter if you are ok with them.

IPv4 or IPv6 public address: <ipvps>
```

```bash
Public interface: eth0
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


```
First DNS resolver to use for the clients: 1.1.1.1
```

```
Second DNS resolver to use for the clients (optional): 1.0.0.1
```

```
WireGuard uses a parameter called AllowedIPs to determine what is routed over the VPN.
Allowed IPs list for generated clients (leave default to route everything): 0.0.0.0/0,::/0
```

**Ne touchez pas aux options**, elles sont très bien auto-générées et on les modifiera par la suite.

```
Press any key to continue...
```

**Une fois** tout ce QCM rempli, **il va tout préparer** et nous **demandera** ensuite **le nom de notre tout premier client**.

```bash
Client name: MaVM
```

Ici, pour lui donner un nom facile à reconnaître je vais l'appeler **MaVM**, mais vous pouvez l'appeler comme vous le souhaitez.

```bash
Client's WireGuard IPv4: 10.66.66.2
```

```
Client's WireGuard IPv6: fd42:42:42::2
```

**Il nous demande ici une ip**, **laissez là comme elle est**, nous la changerons plus tard.

## 2.2.1 - Configuration du serveur Wireguard

Toute la configuration s'effectue dans /etc/wireguard/wg0.conf :

```
nano /etc/wireguard/wg0.conf
```

**Retirez** les lignes commençant par PostUp et PostDown :

```
PostUp = ....................................................
PostDown = ....................................................
```

**Rajoutez** les lignes suivantes au même endroit :

```bash
PostUp = iptables -I FORWARD -i eth0 -o wg0 -s 10.66.66.0/24 -j ACCEPT; iptables -I FORWARD -i wg0 -o eth0 -d 10.66.66.0/24 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -I FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i eth0 -o wg0 -s 10.66.66.0/24 -j ACCEPT; iptables -D FORWARD -i wg0 -o eth0 -d 10.66.66.0/24 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

Vous pouvez **sauvegarder et quitter** le fichier avec CTRL + X Y Entrée

**Ajustez** les réglages de gestion de paquets du linux avec la commande suivante :

```bash
echo 'net.ipv4.ip_forward=1
net.ipv4.conf.all.proxy_arp=1
net.ipv6.conf.all.forwarding=1' | tee -a /etc/sysctl.conf
```

Une fois ceci fait, vous pouvez redémarrer votre VPS avec la commande :

```bash
reboot
```

Le serveur Wireguard est maintenant prêt à accueillir différent type de profils.

## 3.1 - Un serveur VPN avec des IP dédiées

Si vous êtes intéressés par l'auto-hébergement, cette solution (historique à la documentation) vous montre comment affecter des adresses IPs dédiées à nos clients.

**Il est necéssaire que vous ayez une adresse IP additionnelle pour continuer ce cas d'usage.**

1. Générez un profil Wireguard comme le cas précédent avec la commande **bash wireguard-install.sh**
   Laissez l'ip par défaut, nous la modifierons juste après.
   *Vous pouvez également modifier le profil qui a été généré précédemment wg0-client-MaVM*
   
2. Modifions la configuration côté serveur avec **nano /etc/wireguard/wg0.conf** :
   ![](https://img.creeper.fr/Kiba9/pEFITIsu80.png/raw)
   Vous devez rajouter à la fin du fichier l'adresse IP Additionnelle comme ceci :
   ![](https://img.creeper.fr/Kiba9/nenUloxe42.png/raw)
   Une fois la modification apportée, vous pouvez quitter le fichier en faisant CTRL+X Y Entrée

3. Redémarrez le serveur Wireguard avec la commande suivante : **systemctl restart wg-quick@wg0**

4. Modifiez également le fichier client présent dans le dossier /root : **nano /root/wg0-client-ipdedieee.conf**

   ![](https://img.creeper.fr/Kiba9/DIRaxeTo15.png/raw)
   Et interchangez l'addresse IP privée (10.66.66.X) par l'addresse publique que vous avez associé au profil côté serveur (l'ip dédiée qu'on a rajouté précédemment)

   Rajoutez également juste en dessous de DNS la ligne suivante :

   ```
   PostUp = iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o wg0 -j TCPMSS --clamp-mss-to-pmtu
   ```

   Le fichier doit ressembler à ceci :
   ![](https://img.creeper.fr/Kiba9/LoCUSIfU59.png/raw)
   Une fois la modification apportée, vous pouvez quitter le fichier en faisant CTRL+X Y Entrée

Le profil est prêt ! Vous pouvez désormais le déployer sur une VM Linux ou Windows !
Attention, il est important de savoir que une fois le profil monté, l'intégralité des ports de la machine seront joignables depuis l'extérieur.
Faites donc attention à :

* Utiliser des mot de passes robustes (ou des clés SSH)
* Maintenir la machine à jour pour éviter des vulnérabilités flagrantes

Vous pouvez également connecter vos machines entre elles via le VPN en utilisant les adresses en 10.66.66.X !

Vous pouvez suivre cette rubrique de la documentation pour monter l'IP sur une VM Linux.

## 3.2 - Un simple serveur VPN

Le premier cas d'usage est un simple serveur VPN. Vous pouvez créer autant de profils que vous le souhaitez, et une fois connecté, votre adresse sera masquée par celle de votre VPS.
Cela peut-être utile si vous souhaitez télécharger du contenu en masquant votre adresse IP avec une connexion chiffrée, ou bien masquer votre adresses aux vilains internautes malveillants.

**Il suffit d'utiliser les profils générés nativement par le script wireguard-install.sh**

Pour générer un profil :

1. **bash wireguard-install.sh**
2. **Add a new user**
3. Donnez un nom à votre profil, et laissez les adresses ip proposées par défaut.
4. Votre profil est disponible dans le dossier /root/ ou bien scannez le QR-Code sur l'application mobile pour utiliser le profil.

![](https://img.creeper.fr/Kiba9/BIliBAyO08.png/raw)

Vous pouvez monter ce profil sur un Windows avec le client Wireguard téléchargeable depuis leur [site internet](https://www.wireguard.com/install/).
Vous pouvez également le monter sur n'importe quel appareil mobile que ce soit [Apple](https://apps.apple.com/fr/app/wireguard/id1441195209) ou [Android](https://play.google.com/store/apps/details?id=com.wireguard.android&hl=fr&gl=US).
Si vous souhaitez monter le profil sur une distribution Linux, référez-vous à cette partie de la documentation.

## 3.3 - Un serveur VPN ++ avec une gateway en bonus !

coming soon

## 3.4 - VPN + Reverse proxying

Pour pouvoir gérer plus facilement nos flux web, nous pouvons également installer un Reverse Proxy sur le VPS HMS, et router à l'aide des profils wireguard les bons sites aux bons endroits.
Cela fait économiser des ressources, en centralisant l'instance Nginx sur le VPS HMS qui sert de coeur de réseau, et en réduisant le nombre d'adresses IPV4 publiques utilisées.

Commençons tout d'abord par installer Docker sur notre VPS :

```bash
curl -sSL https://get.docker.com | sudo bash
```

Créer un dossier où nous installerons notre nginxproxymanager :

```bash
mkdir nginxproxymanager
cd nginxproxymanager
```

Installer le docker-compose.yml :

```bash
nano docker-compose.yml
```

```yaml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    network_mode: host
    environment:
      DISABLE_IPV6: 'true'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
```

Vous pouvez ensuite démarrer l'instance avec la commande suivante :

```bash
docker compose up -d
```

Vous pouvez vous rendre sur l'interface d'administration via http://ip-vps:81/

![](https://img.creeper.fr/Kiba9/fUTePeMO18.png/raw)

Vous pouvez vous connecter à l'interface web avec les identifiants par défaut :

```
username : admin@example.com
password : changeme
```

Et changer le mot de passe par défaut.

![](https://img.creeper.fr/Kiba9/tuQUwUmU80.png/raw)

Commençons par générer des certificats SSL, ce sont des certificats gratuit qui vous permettront d'avoir l'HTTPS sur vos services !

Il est nécessaire que vous ayez :

* Un nom de domaine
* Le contrôle de la Zone DNS (passez-le chez cloudflare l'ui est mieux)
* Une règle DNS A qui pointe vers l'IP principale du VPS HMS

![](https://img.creeper.fr/Kiba9/QicegAwo63.png/raw)

Je vais générer un certificat pour doc.creeper.fr

Rendez-vous via la barre de navigation dans la rubrique SSL Certificates 

![](https://img.creeper.fr/Kiba9/bIKImOkU61.png/raw)

Puis cliquez sur Add SSL Certificate

![](https://img.creeper.fr/Kiba9/jOyikAPi20.png/raw)

Renseignez tout en haut le nom de domaine du service que vous souhaitez générer. Il est également possible de spécifier *.votredomaine.fr mais il faudra utiliser un DNS Challenge pour valider le certificat. Le DNS Challenge peut varier en fonction de votre registrar DNS.

![](https://img.creeper.fr/Kiba9/KiLOdELU62.png/raw)

![](https://img.creeper.fr/Kiba9/RICOWutO99.png/raw)

Une fois le certificat généré, nous pouvons créer le service associé dans la rubrique "Hosts"

![](https://img.creeper.fr/Kiba9/YAFiSutI96.png/raw)

Cliquer sur "Add Proxy Host"

![](https://img.creeper.fr/Kiba9/vikEQuVe99.png/raw)

![](https://img.creeper.fr/Kiba9/JEtUnERE97.png/raw)

Dans Domain Names : sousdomaine.votresite.fr
Scheme :
C'est ce que vous voyez en service local. Par exemple http://ip:8123
Il faudra mettre Scheme http, forwardip ip, forwardport : 8123

Vous pouvez également cocher Block Common Exploits et Websockets Support

![](https://img.creeper.fr/Kiba9/QewiwebO93.png/raw)

Dans la rubrique SSL, séléctionnez le certificat SSL généré précédemment, et cochez Force SSL et HTTP/2 Support.

![](https://img.creeper.fr/Kiba9/pEmICuKI58.png/raw)

Vous pouvez ensuite sauvegarder en cliquant sur "Save"

![](https://img.creeper.fr/Kiba9/lUTuVEzU83.png/raw)
