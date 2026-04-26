# 🎮 Gwanur — Game Design Document

## Vision du Jeu

**Gwanur** est un jeu d'exploration et de puzzles coopératif local, jouable en split-screen vertical sur PC. Inspiré de *It Takes Two* pour la mécanique coop et des RPG pour la progression de personnage. Aucun combat — uniquement des puzzles nécessitant la coordination des deux joueurs.

**Ambiance :** Heroic fantasy médiéval, style Studio Ghibli / Anime semi-réaliste  
**Durée estimée :** ~10 heures  
**Plateforme :** PC  
**Coop :** Local, split-screen vertical (clavier/souris + manette)

---

## Mécanique Centrale — La Complémentarité

Chaque puzzle a **toujours** une solution de base accessible, enrichie par les skills débloqués.

### La règle d'or
> Les skills ne débloquent jamais UN chemin. Ils débloquent COMMENT vous le traversez.

### Les 3 niveaux de chaque puzzle
```
🟢 Solution de base    — toujours accessible, un peu plus long
🟡 Solution 1 skill    — plus fluide, récompense le build
🟠 Solution 2 skills   — expérience enrichie, lore bonus
```

### Exemple concret — La Grande Porte
```
Sans skills
└─ Kael fait pousser une liane + Mira utilise son grappin = 5 min

Avec Floraison (Kael)
└─ Kael ouvre directement un passage végétal = 1 min

Avec Lecture (Mira)
└─ Mira déchiffre le mécanisme = 30 secondes

Avec les deux
└─ Cinématique unique + fragment de lore d'Aelindra 🌸
```

---

## Système de Puzzles Coop

Les puzzles exploitent toujours les équipements des deux personnages ensemble.

### Exemple de séquence
```
Kael fait pousser une liane jusqu'en hauteur
  → Mira utilise son grappin pour se balancer
    → Elle active un mécanisme
      → Qui libère de la lumière
        → Que Kael dirige avec ses brassards pour ouvrir une porte
```

Ni l'un ni l'autre ne peut avancer seul. Le jeu raconte leur interdépendance même quand les personnages ne veulent pas se l'avouer.

---

## Progression RPG — Arbres de Compétences

### 🌿 Arbre de Kael — Magie Naturelle
```
Magie Naturelle
├── Communion       — Parler aux animaux plus complexes
├── Floraison       — Faire pousser des structures plus grandes
└── Vision          — Sentir les secrets cachés dans la nature

Lien Elfique
├── Mémoire des Anciens — Comprendre les langues oubliées
├── Résonance           — Amplifier la magie de Mira
└── Harmonie            — Calmer des zones entières
```

### 🔥 Arbre de Mira — Instinct Humain
```
Instinct Humain
├── Précision       — Grappin plus loin, plus rapide
├── Débrouillardise — Crafter des objets plus complexes
└── Lecture         — Décrypter mécanismes et codes anciens

Robustesse
├── Endurance       — Résister à des environnements hostiles
├── Ancrage         — Tenir des positions pour que Kael puisse agir
└── Sens du danger  — Détecter les pièges cachés
```

### Ce que les skills apportent
1. **Raccourcis élégants** — un puzzle en 5 min devient fluide en 1 min
2. **Contenu bonus caché** — chemins secrets, coffres optionnels
3. **Lore et narration exclusive** — fragments d'histoire supplémentaires

---

## Système de Moralité

Chaque jumeau a son propre curseur de moralité, indépendant.

```
Kael :  Instinct  ←————————→  Raison
Mira :  Méfiance  ←————————→  Confiance
```

### Les choix narratifs influencent les skills
À la fin de chaque zone, les joueurs font un choix ensemble. Ce choix débloque des skills différents.

#### Exemple — Zone 1, le grimoire d'Aelindra
```
❓ Vous trouvez un vieux grimoire de votre mère.
   Vous le gardez secret entre vous ?

[Oui, c'est notre secret]
  → Kael débloque : Résonance
  → Mira débloque : Ancrage

[On le partage avec les villageois]
  → Kael débloque : Mémoire des Anciens
  → Mira débloque : Lecture
```

Aucun chemin n'est meilleur. Juste différent. Idéal pour rejouer.

### Effets de la moralité sur les dialogues
```
Kael Instinct élevé  → Les animaux lui parlent en premier
Kael Raison élevée   → Il comprend mieux les mécanismes anciens

Mira Confiance élevée → Les PNJ lui confient des quêtes secrètes
Mira Méfiance élevée  → Elle détecte les trahisons avant qu'elles arrivent
```

### Fins selon la moralité
```
🌸 Kael Instinct + Mira Confiance
   → Fin chaleureuse, les Terres Grises s'ouvrent à eux

❄️ Kael Raison + Mira Méfiance
   → Fin plus sombre, ils avancent mais laissent des blessures

🌿 Combinaisons mixtes
   → Fins nuancées, ni tout blanc ni tout noir
```

---

## Les PNJ — Archétypes

| Type | Description |
|---|---|
| **L'Indécis** | Change de camp selon qui lui parle en dernier |
| **Le Mémorieux** | Se souvient de tout ce que vous avez fait avant |
| **Le Miroir** | Reflète exactement votre moralité |
| **Le Juge** | Teste intentionnellement les deux jumeaux différemment |

### La mécanique sociale
Certains PNJ réagissent différemment à chaque jumeau dans la même conversation. Les joueurs doivent se coordonner sur QUI parle en premier selon la situation. C'est un **puzzle social**.

---

## Structure des Zones

| Zone | Lieu | Durée | Mécanique clé |
|---|---|---|---|
| 1 | Village des Lisières | 1h30 | Introduction, puzzles simples |
| 2 | Forêt Entrelacée | 2h | Nature et lumière |
| 3 | Ruines de l'Entre-Deux | 2h30 | Mécanique et échos du passé |
| 4 | Lac des Reflets | 2h | Dualité et reflets |
| 5 | Cœur des Terres Grises | 2h | Choix final |

---

## Mécanique des Personnages — Détail

### Principes de design (public cible : couples avec un non-gamer)

- **Zéro timing critique** — les puzzles se basent sur l'observation et la coordination, jamais sur les réflexes
- **Chaque bouton = une seule chose** — le non-gamer ne doit jamais chercher le bon bouton
- **Points d'interaction mis en évidence** — plantes qui réagissent visuellement, points d'accroche qui brillent légèrement. Pas besoin de chercher.

### 🌿 Kael — Mécaniques détaillées

**Brassards de Sève (X)**
- Version automatique : la liane pousse vers la surface végétale la plus proche dans la direction de Kael. Pas de visée manuelle.
- Base : liane courte (20s), depuis toute surface végétale devant lui
- Avec Floraison : structures plus grandes (pont de branches, plateforme d'écorce), durée plus longue
- Avec Floraison + Vision : la végétation pousse légèrement vers les solutions cachées

**Corne d'Appel (Y)**
- Attire les petits animaux proches (oiseaux, lapins) — ils restent calmes, peuvent peser sur un mécanisme ou transporter un objet
- Avec Communion : Kael comprend ce que les animaux "disent" — indice visuel/directionnel sur un puzzle
- Portée : 8m (rayon de la sphère de détection)

**Le calme comme ressource (Zone 2+)**
- La forêt ne répond à Kael que s'il est immobile et calme
- S'il court ou agit, les plantes se referment
- Crée une tension naturelle avec la dynamique de Mira : il doit s'arrêter au moment où elle a besoin qu'il agisse

### 🔥 Mira — Mécaniques détaillées

**Grappin de Cuivre (X)**
- Vise le point d'accroche le plus proche dans sa direction (ciblage assisté)
- En mode déplacement : bascule d'un point à l'autre
- En mode puzzle : reste fixé jusqu'à annulation — devient un ancrage pour maintenir une position

**Lanterne à Mémoire (Y)**
- **Toujours accessible** : éclaire les zones sombres
- **Échos (flous) accessibles de base** : silhouettes, ambiance, pas d'information précise — Mira voit qu'il s'est passé quelque chose, mais c'est illisible
- **Échos nets** : seulement si Mira a réuni un "contexte" avant — parler à quelqu'un qui était présent, trouver un objet lié à la scène, lire une inscription
  > Loop : trouver un indice → revenir avec la lanterne → comprendre → débloquer le puzzle
- **Mémoire Profonde (skill)** : accès aux échos très anciens (Zone 3+)

**Sac d'Alchimiste**
- Collecte des matériaux dans le monde (plantes que Kael fait pousser, minerais, fragments)
- Craft d'objets simples : clé improvisée, contrepoids, éclat de cuivre poli
- Disponible dès Zone 2 pour le puzzle Rayon Brisé

---

## Types de Combos Kael × Mira

Quatre types de puzzles coop construits autour de la complémentarité des équipements :

| Type | Ce qui se passe | Exemple |
|---|---|---|
| **Construction** | Kael construit → Mira traverse | Liane → grappin → mécanisme |
| **Animal Relay** | Kael attire → animal porte/active → Mira récupère | Corne → oiseau sur mécanisme → Mira passe |
| **Passé-Présent** | Mira voit l'écho → Kael recrée → passage s'ouvre | Lanterne → silhouette d'ancienne plante → Brassards font repousser |
| **Craft Dépendant** | Kael produit → Mira fabrique → objet résout | Brassards font pousser plante rare → Mira récolte → craft une clé |

---

## Zone 1 — Puzzles Détaillés

### Puzzle 1 — La Porte à Deux Poignées (Construction)
Kael (gauche) et Mira (droite) tirent ensemble — la porte monte.
- **Mécanique** : premier joueur presse → attend. Second presse → porte s'ouvre (pas de timing critique)
- Le joueur qui lâche réinitialise sa moitié
- **Fonction pédagogique** : introduction à la coop simultanée

### Puzzle 2 — L'Oiseau et le Passage (Animal Relay)
Kael sonne la Corne → l'oiseau vole vers la plateforme de poids → la grille s'ouvre. Mira dispose de 12s pour passer et activer le verrou.
- **Mécanique** : si Mira n'atteint pas le verrou à temps, l'oiseau repart, la grille se referme, reset
- Prérequis : parler à Lira (déclenche le dialogue de l'oiseau blanc)
- **Fonction pédagogique** : introduction de la Corne + coordination avec contrainte de temps légère

### Puzzle 3 — La Roue d'Eau (Passé-Présent)
Mira tient sa Lanterne allumée → l'écho de la liane devient visible → Kael fait pousser la liane réelle → la roue tourne → le pont s'étend.
- **Prérequis** : parler à Brennan (contexte de la liane)
- **Mécanique** : Mira doit rester dans la zone lanterne. Si elle bouge, l'écho disparaît et Kael ne peut plus agir
- **Fonction pédagogique** : introduit la dépendance positionnelle + rôle de la Lanterne

---

## Zone 2 — La Forêt Entrelacée

### L'identité de la zone

Zone 1, l'environnement était passif — les joueurs agissaient *sur* lui. Zone 2, **la forêt est un personnage**. Elle réagit, elle observe, elle teste. Les arbres ont vu Aelindra passer. Ils savent des choses.

### La mécanique centrale — La Forêt Parle

Chaque personnage reçoit une information *différente* de la forêt :
- Kael touche un arbre avec ses Brassards → il *ressent* un fragment (direction, émotion, image floue)
- Mira allume sa Lanterne sur un autre arbre → elle *voit* un écho différent

Ni l'un ni l'autre n'a le tableau complet. **Ils doivent se parler pour comprendre — la conversation entre joueurs devient la mécanique centrale de la zone.**

### Puzzle 1 — La Porte des Deux Cœurs (Construction + Synchronisation)
Un mur de branches vivantes bloque le chemin. Deux empreintes lumineuses, une par personnage. La forêt doit *sentir* les deux présences en même temps.
- Kael s'arrête et pose les mains (Brassards)
- Mira plante son grappin dans le sol comme ancrage et tient position
- Si l'un bouge, le mur se referme
- **Évolution de Puzzle 1 Zone 1** : même structure, mais c'est la forêt qui exige la sync, pas un mécanisme

### Puzzle 2 — Le Rayon Brisé (Craft Dépendant + Spatial)
Un rayon de soleil entre par la canopée mais se perd avant d'atteindre un mécanisme au sol.
- Kael fait pousser des lianes à des angles précis pour dévier un fragment du rayon
- Mira positionne avec le grappin un éclat de cuivre poli (craftée avant avec le Sac) sur un point d'accroche en hauteur
- Les deux fragments doivent frapper la cible **en même temps**
- **Première fois que la coordination spatiale compte** — pas de réflexes, mais une vraie organisation dans l'espace

### Puzzle 3 — Les Deux Mémoires (Passé-Présent + Communication verbale)
Deux arbres anciens ont vu Aelindra pour la dernière fois. Chacun porte la moitié d'un rituel.
- Kael touche le premier → ressent : elle a commencé par invoquer quelque chose à gauche
- Mira éclaire le second → voit : elle a terminé par une offrande à droite, et quelque chose entre les deux

Ni l'un ni l'autre ne sait ce qui est "entre les deux". Ils doivent déduire la séquence ensemble et la reproduire — Kael fait pousser, Mira positionne, dans le bon ordre.

**Révélation narrative** : après le puzzle, le Gardien sort et dit *"Vous avez reproduit le geste de la Tisserande."* — premier indice sur le vrai titre d'Aelindra.

### Choix de fin de Zone 2
Après avoir rencontré le vieux Gardien elfique : décident-ils de lui faire confiance et révéler qui est leur mère, ou gardent-ils le secret ?

---

## Technique

- **Moteur :** Godot 4.6 (Forward Plus)
- **Rendu :** 3D, style semi-réaliste anime
- **Split-screen :** Vertical, deux SubViewports avec `own_world_3d = false`
- **Contrôles :** Deux manettes (device 0 = Kael, device 1 = Mira), clavier ZQSD comme fallback développeur
- **Personnages :** Modèles 3D base Meshy AI, affinés sur VRoid/Blender
- **Animations :** Mixamo pour les animations de base
