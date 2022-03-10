---
layout: post
title: Wireguard : Un protocole vraiment illimité ?
description: J'ai "enquêté" sur pourquoi je n'arrive pas à tirer plus de 3Gbps sur plusieurs serveurs Wireguard, et j'ai peut-être trouvé la réponse !
summary: Le protocole Wireguard, possède-t-il vraiment une limite ?
tags: [tunnel]
---
J'ai toujours été **ambassadeur** **Wireguard**.
C'est un protocole que **j'apprécie vraiment**, qui est **très** **performant**, **flexible**, et extrêment **rapide**.
Je m'en suis toujours servi, en **4G**, en Wifi, en Fibre 2G Orange, mais désormais en 10G Free.
Et je pensais initialement un **problème de peering** du côté de Free qui me limitait à 2Gbps vers beaucoup de serveurs Speedtest, mais après quelques recherches, **j'ai fait une toute autre découverte**.

# Les conditions du test :

Pour vérifier les limites du protocole Wireguard, rien de mieux que tester en **local**.
Pour cela, je vais utiliser mon LAN en tant que bench lab.

* L'intégralité du chemin réseau effectué est réalisé en **SFP+ DAC & AOC**.
* Le logiciel utilisé sera la dernière version de **iPerf3**
* Le serveur possède 32 coeurs à 3.3Ghz (**E5-2267v2**), sur un ESXi (machine virtuelle)
* Le client possède 12 coeurs à 3.6Ghz (**R5-3600**) sur Fedora 35 (bare metal)

# Un premier test sans WG

Pour commencer, je vais ping la machine virtuelle et prendre en compte toutes les valeurs.
Je précise qu'il y a tout type de traffic sur mon réseau, mais que le débit switché n'est en aucun cas impacté.

### Ping : **Moi --> Serveur (Sans WG) :**

<img src="https://i.imgur.com/KN7JUQ5.png" alt="Moi --  > Serveur (Sans WG)" />

### iPerf3 : **Moi --> Serveur (Sans WG) :**

![](https://i.imgur.com/0WOjivQ.png)

(commande utilisée : `iperf3 -c <ip-du-serveur> -R -P 105 -t 5000`)

On constate du **9.40Gbits/sec** et une moyenne de **0.353ms ping**.

# Un second test avec WG

Pour installer mon serveur Wireguard, j'ai utilisé le script suivant : [wireguard-install](https://github.com/angristan/wireguard-install)

J'ai ensuite directement monté le profil sur ma tour, sans aucun réglage supplémentaire.

### Ping : **Moi --> Serveur (Avec WG) :**

![](https://i.imgur.com/ASZ6zVa.png)

### iPerf3 : **Moi --> Serveur (Avec WG) :**

![](https://i.imgur.com/yEgxkam.png)

On constate ici **3.10Gbits/sec** et une moyenne de **0.500ms ping**.
Ce qui peut parraître pas grand chose de plus, mais est nettement supérieur en perte de débit.

En ce qui en est de la charge du CPU quand un test iperf3 est réalisé :

### **CPU Serveur :**

![](https://i.imgur.com/iyMCYtw.png)

### **CPU Client :**

![](https://i.imgur.com/OAqDT0E.png)

Aucune sature, mais pourtant une limite est bien là. Celle du protocole :(

# La limite des 3Gbps ?

Malheuresement, et d'après mes tests Wireguard est bel et bien limité à ~3Gbps. Et on ne pourra pas tirer plus.
Je pensais être paranoïaque d'avoir des meilleurs tests dans certains pays mais de ne jamais atteindre les >3Gbps, et tout s'explique ici.

Je continuerais toujours de recommander Wireguard, mais il va peut-être falloir que je trouve une alternative.
