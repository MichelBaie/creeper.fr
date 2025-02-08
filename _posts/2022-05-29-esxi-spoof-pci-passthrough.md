---
layout: post
title: Spoofer une machine virtuelle ESXI 8
description: Certains logiciels ou jeux bloquent les machines virtuelles par crainte de triche. Voici comment contourner ce blocage.
tags: [esxi]
---

Après avoir configuré le PCI Passthrough sur une machine virtuelle [ESXi](https://en.wikipedia.org/wiki/VMware_ESXi), pour refaire un [Shadow](https://shadow.tech/fr-FR) à la maison grâce à [Parsec](https://parsec.app/), j'ai rencontré un problème : certains jeux sont bloqués car leur système anti-triche (EAC/Vanguard) détecte que je joue sur une machine virtuelle. Heureusement, je ne suis pas un tricheur, et j'ai trouvé une solution pour contourner ce blocage !

## Solution pour contourner le blocage

Pour ce faire, il suffit d'ajouter les arguments suivants dans les paramètres de votre machine virtuelle :

```plaintext
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

Ainsi que :

```plaintext
SMBIOS.reflectHost = TRUE
hypervisor.cpuid.v0 = FALSE
```

## Conclusion

Avec ces modifications, vous devriez pouvoir lancer n'importe quel jeu sans être bloqué par les systèmes anti-triche. Bon jeu 🎮 !