---
layout: post
title: Spoof une machine virtuelle ESXI 8
description: Certains logiciels ou jeux bloquent les machines virtuelles pour peur de cheat, voici comment contourner ce blocage.
tags: [esxi]
---

Hello !

Après avoir fait du PCI Passtrough, j'ai certains jeux qui sont bloqués car l'Anti-Cheat n'apprécie pas trop les machines virtuelles.
Heureusement, je ne suis pas un tricheur, et j'ai trouvé quelques arguments afin de faire sauter ce blocage :

```
monitor_control.disable_directexec = "true"
monitor_control.disable_chksimd = "true"
monitor_control.disable_ntreloc = "true"
monitor_control.disable_selfmod = "true"
monitor_control.disable_reloc = "true"
monitor_control.disable_btinout = "true"
monitor_control.disable_btmemspace = "true"
monitor_control.disable_btpriv = "true"
monitor_control.disable_btseg = "true"
```

et 

```
SMBIOS.reflectHost = TRUE
```

Il faut rajouter ces arguments dans les paramètres de la Machine Virtuelle :

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919458906198036/firefox_SQmpH7euze.png)

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919376551034930/firefox_BKR927lYtN.png)

![](https://cdn.discordapp.com/attachments/926788575293472798/1094919272762970174/firefox_nfWxg5PCEp.png)

Normalement vous devriez pouvoir lancer n’importe quel jeu désormais !
