# Avoir des IP FO chez soi (grâce à OVH et quelques tunnels)

Pour mettre un peu de contexte, j'ai récupéré chez moi un serveur qui fait tourner pas mal de machines virtuelles. Bénéficiant de la fibre, je souhaite héberger des services pour la famille, des amis, et des personnes à qui je parle. 
Seulement, avec une seule IP (résidentielle), je suis très vite limité par mon nombre de ports mis à ma disposition, et je suis vite obligé de faire un choix sur quels services héberger, ou éteindre...
Mais heureusement qu'avec un peu de temps et d'argent, je peux désormais bénéficier d'IP dédiées à mes machines virtuelles. Ce sont des IP OVH (qui bénéficient de protection Anti-DDOS), qui sont localisées dans plusieurs pays du monde, et qui ne coûtent seulement 2€50 !
Ça a changé ma manière d'héberger chez moi, et je tenais à vous partager ma solution.

Je précise que je ne suis pas un expert réseau, pour certaines personnes cette technique peut sembler sale ou incomplète, mais pour mon utilité elle est parfaite.
De plus, ce tuto est une seconde version grâce à la contribution de beaucoup de personnes qui m'ont aidé à avoir un résultat très qualitatif et stable, ils sont mentionnés à la fin de cet article.

## 1 - Les pré-requis

* Un VPS OVH (C'est plus pratique, je ne ferais pas de support pour les autres hébergeurs)
* Des IP Failover (Elles coûtent 2€50 l'unité, et sont possédées jusqu'à l'expiration du VPS)
* Debian 11> ou Ubuntu 21> (Du moment qu'on a un kernel linux 5.10>, qui supporte nativement WireGuard)
* Un bon ping (C'est préférable pour nos services)

Justifications :

* J'ai choisi OVH, car c'est l'un des seuls (ou le seul ?) hébergeur français à proposer des adresses IP à 2€50 à vie, ce qui peut réduire fortement nos coûts mensuels, car dans beaucoup d'autre hébergeurs on paie plus cher l'IP et on la paie par mois...
* Pour le tunnel, nous allons utiliser Wireguard, un protocole VPN qui passe sur de l'UDP. Il est compatible avec énormément de plateformes, est extrêmement léger, très facile à déployer et beaucoup plus performant que ses concurrents, tout en restant chiffré. C'est un petit nouveau (qui commence à dater) qui viens tout juste d'arriver dans le domaine de l'open-source et qui as fait ses preuves chez moi.
* La qualité du réseau dépendra de votre réseau, Wireguard ne nécéssite pas une bonne connexion internet, et ne réduira pas votre débit. Cependant, vous devrez rajouter le ping entre vous,ovh et ovh, vous. Pour du jeu, le ping est critique.
* Debian 11> et Ubuntu 21> intègrent enfin Wireguard dans leurs kernels linux natifs en production, ce qui va réduire les commandes de construction qu'étaient présentes dans l'ancienne version du tutoriel. Cependant, il faut obligatoirement (si vous suivez à la lettre ce tutoriel) que vous utilisez le même OS que moi.

## 2 - Installons notre VPS

Une fois que vous avez acheté le VPS qui correspond à vos besoins, puis acheté une IP Failover liée à votre VPS, nous pouvons commencer.

Dès que vous avez reçu vos identifiants