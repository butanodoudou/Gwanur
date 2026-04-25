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

## Technique

- **Moteur :** Godot 4
- **Rendu :** 3D, style semi-réaliste anime
- **Split-screen :** Vertical, deux Viewports indépendants
- **Contrôles :** Joueur 1 clavier/souris, Joueur 2 manette
- **Personnages :** Modèles 3D base Meshy AI, affinés sur VRoid/Blender
- **Animations :** Mixamo pour les animations de base
