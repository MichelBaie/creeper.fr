## Avoir des IP Failover OVH chez soi (grâce à Wireguard)

```
⚠ Une mise à niveau de ce tutoriel est nécessaire pour :

* l'arrivée de Debian 11,

* et Wireguard nativement dans le kernel linux 5.10>

Ces sujets peuvent donc ne pas être complets et je vous conseille de les ignorer tant que cet avertissement persiste. ⚠
```

Hey !

J'ai un serveur chez moi, et j'ai besoin d'IP...

Grâce à mes **IP Failover**, j'évite de donner celle de ma box qui est vulnérable, et je donne celle **d'OVH** [protégée par leur petite protection DDOS](https://www.ovh.com/fr/anti-ddos/technologie-anti-ddos.xml).

Si vous souhaitez faire la même chose que moi, vous êtes au bon endroit.

C'est compatible Windows, Linux et tout autre étant donné que [WireGuard](https://www.wireguard.com) est un [VPN d'Avenir](https://www.google.com/search?q=wireguard&tbm=nws) qui est désormais inclut dans beaucoup de kernels.

### 1 - Commençons par commander un VPS OVH

Pourquoi j'ai choisi **OVH** ?

Le triste gros avantage d'OVH c'est que c'est (à ma connaissance) le seul hébergeur français à proposer l'achat d'**IP Failover à** **2€50 à vie** (tant que le service reste actif). Cela va nous permettre de réaliser de **sérieuses économies** au bout d'un an.

Maintenant il faut également comparer un **VPS** et une offre **Public Cloud** : deux offres proposées par OVH qui sont idéales pour notre utilisation.

- L'avantage d'un [VPS](https://www.ovhcloud.com/fr/vps/compare/) c'est que les offres commencent directement à partir de **débits supérieurs à 100MB/S** : Si vous faites tourner un **RDP Windows** les téléchargements seront **limités** à ce débit. Cependant, la qualité du réseau sera tout aussi stable.
- L'avantage d'un [Public Cloud](https://www.ovhcloud.com/fr/public-cloud/prices/#388) c'est qu'il est **très flexible**, **les prix sont très bas** et le débit est de **minimum 100MB/S** : Si vous souhaitez faire tourner **du web** ou du **serveur Minecraft**, ne nécessitant **pas trop de débit** mais seulement **du ping**.

Voici un petit tableau des prix si vous avez besoin de comparer rapidement :

| s1-2 (Public Cloud Sandbox) | VPS Value        | VPS Essential     | VPS Confort       |
| --------------------------- | ---------------- | ----------------- | ----------------- |
| 100 MB/S                    | 250 MB/S         | 500 MB/S          | 1 GB/S            |
| 2.99€ HT (par mois)         | 5€ HT (par mois) | 10€ HT (par mois) | 20€ HT (par mois) |

Je précise qu'on a **pas besoin de gros** **CPU** ou **RAM**, seulement de réseau car WireGuard est **très léger**.
J'ai **personnellement choisi le tout premier public cloud** : *s1-2*

### 2 - Installons notre VPS

Dans ce tutoriel, je vais utiliser **Debian 10**, cela peut changer certaines choses comme le login SSH ou autre, mais prenez le même que moi au moins on sera sûr d'avoir des choses identiques.
⚠ **Utilisez Debian 10 pour être sûr d'être 100% compatible : Le tuto peut ne pas fonctionner ou bien manquer de repos sur d'autres distrib.** ⚠ 

Voici une petite liste des trucs à faire après avoir reçu notre service :

- Retirer le kernel cloud pas compatible WireGuard

- Installer WireGuard et ses dépendances

- Installer nos IP Failover et quelques règles IPTables

- Créons notre tout premier profil WireGuard


#### Retirer le Kernel Cloud

Connectez-vous en SSH avec de super clients comme [Termius](https://termius.com/) (désolé la team [MobaXTerm](https://mobaxterm.mobatek.net/)) et commençons.

Vous avez normalement reçu par email les identifiants. Si vous avez choisit debian 10 (**ce qu'il faut choisir hein**) le login est `debian` et le mot de passe auto-généré.

```
sudo su -
apt purge linux-image-$(uname -r)
```

Ici, on retire tout les kernels installés sur notre VPS, si vous redémarrez sans avoir terminé les prochaines commandes, le VPS ne démarrera plus donc évitez :/ C'est d'ailleurs pour cela qu'une **pop-up demande si oui ou non** ne devons annuler. **Il faut répondre NON**.
On peut juste après installer le dernier kernel tout propre avec les commandes suivantes :

```
apt update
apt install linux-image-amd64 linux-headers-amd64
```

Une fois notre nouveau kernel d'installé, on peut redémarrer notre VPS avec la commande :

```
reboot
```

On peut se reconnecter et le mettre à jour :

```
apt update
apt full-upgrade
reboot
```

Une fois toutes ces commandes terminées, le VPS aura redémarré à la dernière version ! On est fin prêt pour continuer :)

#### Installer WireGuard sur notre VPS

Maintenant que notre kernel est prêt il nous reste plus qu'a utiliser un script déjà tout fait par la communauté de la toile !

Ajoutons d'abord nos repos (pour Debian 10) :

```bash
sh -c "echo 'deb http://deb.debian.org/debian buster-backports main contrib non-free' > /etc/apt/sources.list.d/buster-backports.list"
apt update
```


Voici les commandes à exécuter pour tout préparer et lancer notre installation :

```
apt install curl bash sudo wget resolvconf wireguard-tools wireguard-dkms dkms wireguard -y
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

Au dessus il demande l'IP publique du VPS, par défaut il devrais bien la détecter donc laissons-là.

```bash
Public interface: eth0
```

On laisse l'interface réseau d'écoute par défaut.

```bash
WireGuard interface name: wg0
```

Toujours laisser l'interface WireGuard par défaut.

```
Server's WireGuard IPv4: 10.66.66.1
```

Ici, il nous demande lequel sera notre réseau virtuel WireGuard. Il faut que ce réseau **ne sois pas utilisé dans votre LAN**, donc ne remplissez pas par votre réseau local, laissez les valeurs par défaut qui marcheront très bien.
Pour l'IPV6 oublions, OVH ne commercialise pas encore d'IPV6 Failover 🤔

```
Server's WireGuard port [1-65535]: XXXXXX
```

Ici, il nous demande le port d'écoute de WireGuard, **notez-le**, on en aura besoin pour plus tard.

```
First DNS resolver to use for the clients: 176.103.130.130
Second DNS resolver to use for the clients (optional): 176.103.130.130
```

Utilisons les meilleurs DNS (chacun son avis) : ceux de [CloudFlare](https://1.1.1.1/) : `1.1.1.1, 1.0.0.1`

Une fois tout ce QCM de remplis, il va tout préparer et nous demandera ensuite le nom de notre tout premier client.

```
Client name: MaVM
```

Ici, pour lui donner un nom facile à reconnaitre je vais l'appeler **MaVM**, mais vous pouvez l'appeler comme vous souhaitez.

```
Client's WireGuard IPv4: 10.66.66.2
```

Ici il nous demande son IP sur le LAN, donc laissez par défaut et tout se passera bien. Mais **notez-le** quand même.

Quand vous avez fini la commande, n'oubliez pas de faire :

`touch /etc/rc.local`
`chmod +x /etc/rc.local`
`nano /etc/wireguard/wg0.conf`

Et remplacez le postUp, postDown par :

```
PostUp = ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; bash /etc/rc.local
PostDown = ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

Puis sauvegardez le fichier. Et on relance WireGuard : 

```
systemctl stop wg-quick@wg0
systemctl start wg-quick@wg0
```

Une fois les commandes terminées, il est possible que quelques erreurs soient survenues et est préférable de redémarrer le VPS.

#### Configurons nos IP Failover

Maintenant il va falloir passer à la caisse. Achetons une IP Failover et lions là a notre service OVH.

###### Pour Public Cloud : 

Rendez-vous dans la sections Failover IP sur l'espace public cloud, il vous proposera de créer un réseau (sans frais). Cela peut prendre jusqu'à 10 minutes. -+N'hésitez pas à actualiser la page, l'espace client est plutôt mou.
Une fois qu'on a notre réseau il vous proposera d'acheter des IP Failover dans la catégorie actions. (Liez la bien au bon service)
Suivez les instructions, payez et une facture vous sera générée. Il faudra attendre jusqu'à 10 minutes (ou le lendemain si vous commandez tard le soir) avant d'avoir enfin reçu son IP.
Une fois reçue, elle devrais apparaître dans la section IP Failover.

###### Pour VPS : 

Rendez-vous sur [l'espace client ovh dans la section server puis ip](https://www.ovh.com/manager/dedicated/#/configuration/ip?tab=ip) puis cliquez sur commander des IP additionnelles. Suivez les instructions et votre IP sera bien linkée sur votre VPS. N'oubliez pas de payer la facture sinon elle n'arrivera jamais et le temps d'attente est en général de 10 minutes ou le lendemain si vous commandez tard le soir.

Maintenant que nous possédons nos adresses IP il va falloir les monter car OVH adore nous compliquer les choses 🤡

J'ai opté pour la solution du **rc.local** : Au démarrage il monte tout.

Modifions notre fichier avec la commande :

`nano /etc/rc.local`

Voici les 5 magnifiques lignes qui vont nous aider à router tout notre Traffic réseau dans le bon sens :

```bash
#!/bin/bash
echo "Oust" # ICI on nettoie si vous utilisez docker retirez les lignes qui suivent
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
echo "tout propre"
ifconfig <eth0> <IPFailover>/32
iptables -t nat -A POSTROUTING -p udp --sport <PortWireGuard> -d <IPFailover> -j SNAT --to-source <IpLanVPN.1>:<PortWireGuard>
iptables -t nat -A POSTROUTING -s <IpLanClientVPN> -j SNAT --to-source <IPFailover>
iptables -t nat -A PREROUTING -p udp --dport <PortWireGuard> -d <IPFailover> -j DNAT --to-destination <IpLanVPN.1>:<PortWireGuard>
iptables -t nat -A PREROUTING  -d <IPFailover> -j DNAT --to-destination <IpLanClientVPN>
```

Je vous explique ce que signifie chacun des arguments <> à remplacer :

* `<eth0:0>` : Pour commencer par la première IP vous pouvez noter **eth0:0** mais à chaque ip de rajoutée : **toujours incrémenter** **eth0:1 eth0:2 eth0:3**

* `<IPFailover>`/32 : Il s'agit de l'IP OVH que vous venez d'acheter.
* `<PortWireGuard>` : Le port WireGuard que je vous ai demandé de noter au dessus.
* `<IpLanVPN.1>` : L'adresse ip du serveur WireGuard (*Server's WireGuard IPv4*)
* `<IpLanClientVPN>` : L'IP Lan que vous avez associé à la VM lors du setup interactif de WireGuard.

On sauvegarde notre fichier avec CTRL X + Y + Entrée et on fais la commande ci-dessous pour lui donner des perms exécutions.
`chmod +x /etc/rc.local`

On peut maintenant exécuter notre script (`bash /etc/rc.local`) et notre transit réseau est désormais prêt.

#### Nettoyer nos clients Wireguard

Par défaut le script n'est pas vraiment optimisé à cet usage. Nous allons donc prendre le client qu'il nous a gentiment générer et le pimper.
Nous allons retirer l'IPV6 et changer la gateway VPN

Celui-ci devrait être situé dans le dossier /root (par défaut quand on est root), il vous suffit donc simplement de faire la commande `ls`  et voici notre premier profil :

```bash
root@s1-2-gra7:~# ls
wg0-client-MaVM.conf  wireguard-install.sh
root@s1-2-gra7:~#
```

ici mon client est `wg0-client-MaVM.conf` mais vous devriez avoir un autre que vous avez définit juste avant.

On va juste débroussailler quelques lignes dans celui-ci afin d'avoir un truc très propre.
Ouvrons-le (`nano monprofil.conf`)

```
[Interface]
PrivateKey = 8HNFm5fD7tE7kPCeJ7PUrRo7N/dhw1X1FPS3n79nZkw=
Address = 192.168.23.2/32,fd42:42:42::2/128
DNS = 1.1.1.1,1.0.0.1

[Peer]
PublicKey = qLpTabk+liUFUPoDklUwr5LKAQSOLdjsUrvCnWeEG1E=
PresharedKey = iLMJy9h5eg8xE5Ou1+BS6hZ716cifCyWD20Dj0MZoRs=
Endpoint = 51.210.39.37:59622
AllowedIPs = 0.0.0.0/0,::/0
```

L'adresse ip Endpoint (51.210.39.37 dans l'exemple ci-dessus), doit être remplacée par l'ip Failover de notre profil. Cela va nous permettre d'éviter de se prendre des attaques ddos de manière généraliste. Seulement 1 service tombera au lieu de tous.

Une fois ceci fait, on peut maintenant sauvegarder notre fichier et c'est bon on a notre profil qui est tout beaucoup tout propre.

Vous pouvez copier coller le contenu du fichier dans un éditeur de texte comme visual studio code et l'enregistrer sous .conf

### Installer Wireguard sur notre VM Client

Wireguard a la particularité d'être multi-os, multi-plateformes, partout. Android, Windows, Linux, Router, Télé, Par-tout.

Vous pouvez [regarder leur documentation](https://www.wireguard.com/install/) qui vous expliquera très simplement comment installer wireguard.
Mais grosso-modo, si vous avez un os très compatible (Debian 10, Ubuntu 18.04/20.04) il vous suffit de faire la commande

`apt install wireguard wireguard-tools wireguard-dkms resolvconf `

Une fois celle-ci faite on a besoin d'installer notre profil. Je vous conseille de vous connecter en ssh et ducoup de ne plus utiliser noVNC (Proxmox) car on ne peut pas copier coller ce qui va nous être très utile. (Pour obtenir l'ip locale : `ip a` )

En ssh, faisons la commande `nano /etc/wireguard/wg0.conf` puis collons notre profil que nous avions pimpé juste avant dans le terminal. Sauvegardons le fichier et voila !

Puis effectuez la commande :

```bash
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0
```

Normalement si vous faites un `curl ifconfig.me` vous devriez voir l'ip failover OVH. Et voilà 😆 on a une première ip OVH sur une VM dans sa maison.

Par défaut avec la commande enable, le service wireguard montera et démarrera au démarrage afin d'avoir aucune commande supplémentaire pour monter notre interface.

### Ajouter d'autres IP supplémentaires

C'est bon ! Vous avez tout en main pour déployer des ips OVH. Néanmoins je vais quand même vous rappeler les commandes nécessaires pour déployer d'autres profils.

Déjà n'oubliez pas d'être root, car tout se passe en root pour la commande `bash wireguard-install.sh`

```bash
It looks like WireGuard is already installed.

What do you want to do?
   1) Add a new user
   2) Revoke existing user
   3) Uninstall WireGuard
   4) Exit
Select an option [1-4]:
```

Sélectionnez 1 afin de déployer un nouveau profil.

Dans le setup il vous demandera a un moment l'ip locale du client, il faut mettre une ip qui n'est Ducoup pas utilisée. Tout à l'heure j'ai pris 10.66.66.2, il faudra donc mettre 10.66.66.3 etc ...

Une fois le setup terminé, le profil sera disponible dans le dossier /root

Ensuite il faut setup les règles iptables donc `nano /etc/rc.local`, rajouter une ligne ifconfig avec cette fois-ci la bonne ip.
Puis copier les règles iptables et remplacer l'ip failover et locale par la nouvelle. Une fois ceci fait n'oubliez pas de mettre les permissions en écriture (`chmod +x /etc/rc.local`) et vous n'avez pas besoin de redémarrer : un simple `bash /etc/rc.local` devrais suffit !

### Infos Pratique

Si vous avez besoin de déployer WireGuard sur des containers LXC suivez [ce tutoriel](http://web.archive.org/web/20210826175543/https://nixvsevil.com/posts/wireguard-in-proxmox-lxc/)

Je rajouterais d'autres infos ici au fur et à mesure des remarques qu'on me fera sur ce tutoriel.



### Merci

Merci d'avoir suivi ce tutoriel, espère que celui vous aura été utile (pour ma part sa m'a changé ma vie, j'ai déjà 16 ip ovh chez moi 😆, la limite :().
Le but de mon site c'est tout ce tutoriel : des trucs utiles qui peuvent servir a tout le monde.

Merci à [Mael](https://github.com/maelmagnien) d'avoir Patch certains bugs dans le tuto.

