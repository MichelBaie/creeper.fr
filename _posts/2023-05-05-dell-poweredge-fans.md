---
layout: post
title: Régler correctement les ventilateurs d'un serveur Dell
description: Dans le cadre d'un homelab, il n'est parfois pas plaisant d'avoir son serveur qui fais énormément de bruit.
tags: [homelab]
---

Bonjour à tous !

Aujourd'hui, je vais vous parler d'un sujet qui préoccupe de nombreux passionnés de homelab : le bruit des serveurs Dell. Posséder plusieurs serveurs à la maison est formidable pour expérimenter et installer diverses applications, mais le bruit généré par les ventilateurs peut vite devenir désagréable.

Après avoir testé plusieurs méthodes, j'ai trouvé une solution simple et efficace pour réduire ce bruit en ajustant quelques paramètres dans le BIOS. Suivez le guide !

## Pourquoi régler les ventilateurs ?

Les serveurs Dell sont conçus pour fonctionner dans des environnements professionnels où le bruit n'est pas une priorité. Cependant, dans un cadre domestique, il est crucial de réduire ce bruit pour améliorer le confort. J'ai initialement tenté de régler la vitesse des ventilateurs via l'IPMI en fonction de la température des processeurs, mais cette méthode n'est pas toujours compatible avec tous les systèmes d'exploitation.

## La solution : un réglage simple dans le BIOS

Après de nombreuses recherches et tests, j'ai découvert un réglage simple dans le BIOS qui permet de réduire considérablement le bruit des ventilateurs. Voici comment procéder :

### Étapes à suivre

1. **Accéder au BIOS** :
   - Allumez votre serveur et appuyez sur `F11` pour accéder au menu de démarrage.
   - Sélectionnez `Launch System Setup` pour entrer dans le BIOS.

   ![](https://github.com/user-attachments/assets/a32daa73-74df-407c-b5a0-b29448b9b362)

2. **Accéder aux paramètres iDRAC** :
   - Dans le BIOS, allez dans `iDRAC Settings`.

   ![](https://github.com/user-attachments/assets/966deb31-bbbb-48fd-bde3-72354c0551c5)

3. **Modifier le profil thermique** :
   - Descendez jusqu'à l'option `Thermal`.
   - Sélectionnez `Thermal Profile` et réglez-le sur `Minimum Power`.

   ![](https://github.com/user-attachments/assets/4a2fb130-c819-4888-ae8a-7a0d961c022d)

Ce réglage permet aux ventilateurs de fonctionner au minimum nécessaire, réduisant ainsi le bruit.

### Important

- Assurez-vous que votre serveur est correctement fermé pendant son fonctionnement. Si l'iDRAC affiche une alerte orange (problème d'ouverture ou d'alimentation), les ventilateurs peuvent tourner plus vite pour alerter l'utilisateur.
- Une fois le réglage effectué, redémarrez votre serveur. Il doit démarrer sur un système d'exploitation pour que les ventilateurs ralentissent en mode Boot.

## Bonus : Réduire la consommation énergétique

En plus de réduire le bruit, vous pouvez également optimiser la consommation énergétique de votre serveur en ajustant les profils de performance dans le BIOS.

### Étapes pour ajuster les profils de performance

1. **Accéder aux paramètres système** :
   - Toujours dans le BIOS (`F11`), allez dans `System BIOS`.

   ![](https://github.com/user-attachments/assets/d87a92f8-c9ac-45d8-8080-92fda14e11c6)

2. **Modifier les profils de performance** :
   - Descendez jusqu'à `System Profile Settings`.
   - Choisissez le profil `Performance Per Watt (OS)`, qui permet à l'OS de gérer une partie de l'alimentation.

   ![](https://github.com/user-attachments/assets/38757880-f01b-4cee-868b-a967f355eec7)

### Conseils supplémentaires

- Si vous utilisez **Windows Server**, installez les pilotes Dell pour une meilleure gestion de l'alimentation.
- Pour les hyperviseurs comme **Proxmox**, **ESXi**, ou **Xen**, aucune configuration supplémentaire n'est nécessaire, car ils sont déjà optimisés pour gérer l'alimentation des serveurs.

## Conclusion

J'espère que cet article vous aura été utile pour réduire le bruit de vos serveurs Dell et optimiser leur consommation énergétique. N'hésitez pas à partager vos astuces et expériences en commentaires !