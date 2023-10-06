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

*Je précise que je ne suis pas un expert réseau, pour certaines personnes cette technique peut sembler sale ou incomplète, mais pour mon utilité elle semble parfaite.* *De plus, ce tuto est une seconde version grâce à la contribution de beaucoup de personnes qui m'ont aidé à avoir un résultat très qualitatif et stable, ils sont mentionnés à la fin de cet article.*

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

## 1.2 - Les différents providers VPS du Marché

Il existe énormément de fournisseurs de VPS sur le marché de l'hébergement. Certains peuvent proposer des offres alléchantes, voir parfois douteuses, mais ne sont pas spécialement de confiance.

Au cours des différentes version de ma documentation, j'ai majoritairement recommandé OVH, hébergeur Français historique qui possède une grande renommée. Mais OVH ayant changé leur politique tarifaire des IP Failover, cette documentation pouvais devenir très chère et donc plus intéressante.

C'est pour cela que je me suis tourné vers HostMyServers, un autre hébergeur Français beaucoup plus récent qui propose encore aujourd'hui des addresses IP additionnelles en facturation définitive. Cela fait depuis 1 an (Septembre 2022) que je suis chez eux, et globalement le service est quali.
Dû à l'afflu d'utilisateurs leur réseau est beaucoup attaqué, ce qui peut poser de courtes interruptions de services (lors d'une grosse attaque), mais ils travaillent activement à améliorer leur Anti-DDOS afin de proposer le service le plus quali possible.

#### **Voici la grille tarifaire d'HMS (Septembre 2023) :** (VPS SSD NVME)

| Modèle                               | SSD-1      | SSD-2      | SSD-4     | SSD-8    | SSD-12   | SSD-12'  |
| ------------------------------------ | ---------- | ---------- | --------- | -------- | -------- | -------- |
| *Prix mensuel sans engagement (TTC)* | 2,99€      | 5,99€      | 9,99€     | 19,99€   | 29,99€   | 39,99€   |
| *Bande passante*                     | 250 Mbit/s | 500 Mbit/s | 800Mbit/s | 1 Gbit/s | 2 Gbit/s | 3 Gbit/s |
| *vCore(s)*                           | 1          | 2          | 4         | 8        | 12       | 12       |
| *Mémoire RAM*                        | 2 Go       | 4 Go       | 8 Go      | 16 Go    | 24 Go    | 32 Go    |
| *Stockage SSD*                       | 20 Go      | 40 Go      | 60 Go     | 120 Go   | 160 Go   | 200 Go   |

Personnellement j'ai pris le SSD-1, l'offre la moins chère toute basique mais qui fonctionne très bien pour mon usage.
Les addresses IP aditionnelles chez HostMyServers coûtent 1,99€ à vie.

**Pour commander une IP Additionnelle**, il faut qu'**une fois le VPS Livré**, vous vous rendez dans l'**Espace Client** (**Votre VPS → Configuration → Commander une Nouvelle IP**), une fois la commande passée, un **mail de confirmation** vous **sera envoyé**.

À l’heure où j’écris cette documentation **les débits ne semblent pas bridés côté VPS**. Le **débit indiqué** sur les offres commercialisées sont simplement **une garantie**.

### 1.3 - Quelques justifications et informations variées

* **Aujourd'hui**, j'utilise **[HostMyServers](https://www.hostmyservers.fr/)**, un hébergeur français 🇫🇷. C'est le seul autre host que je connaisse qui **propose des ipv4 à tarifs "à vie"**. Il propose lui aussi un **Anti-DDOS** correct, et existe depuis un [**certain temps**](https://www.societe.com/societe/hostmyservers-842789000.html).
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

## 2.1 - Préparation réseau du VPS (HOSTMYSERVERS UNIQUEMENT)

**Connectez-vous en SSH** à votre VPS via les **identifiants** qui vous ont été **transmis par mail** ou que vous avez rentré lors de la **première installation**.

**Récemment**, les images des VPS Debian **ont changé**, et utilisent désormais **netplan.io** comme **gestionnaire de réseau**.
Cela **compromettant la documentation**, il est **nécessaire** que nous **revenions à ifupdown**.

**Vérifiez si vous êtes impacté avec la commande suivante :**

```bash
systemctl status networking
```

**Si la commande ci-dessus vous retourne l’erreur suivante :**

![](https://cdn.discordapp.com/attachments/773225836887277599/1135506287052980294/image.png)

Alors vous pouvez exécuter le script suivant :

```bash
curl -fsSL https://gist.github.com/MichelBaie/6abe40bbc72ad4ff9635ced63bc09d41/raw/659aa74d6ad988e2b18b0219f09f8be00cd4eaed/repair.sh -o repair.sh
chmod +x 
sudo sh repair.sh
```

