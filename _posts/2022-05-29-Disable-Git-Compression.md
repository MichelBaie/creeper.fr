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
(Il faut la faire dans le dossier du projet Git)

```
git config core.compression 0
```

Si vous envoyez des fichiers sur GitHub qui ne peuvent pas être compressés, il ne prendra pas 4h et toutes les ressources de votre ordinateur avant de faire le push 😊
