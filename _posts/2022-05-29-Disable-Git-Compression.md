---
layout: post
title: Désactiver la compression de repos Git
description: Certains gros repository peuvent devenir très lent lorsqu'à chaque push on doit compresser les objets.
tags: [git]
---

Hello !

Je touche beaucoup à GitHub en ce moment, et je rencontre beaucoup de soucis avec les gros fichiers.
Le fait qu'ils doivent être compressés avant d'être upload ralentis clairement mon workflow.

Voici une commande simple pour désactiver globalement la compression d'assets de votre client git :

```
git config core.compression 0
```
