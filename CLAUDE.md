# 🌿 Gwanur — Briefing Claude Code

Bienvenue sur le projet **Gwanur**. Lis ce fichier en entier avant de faire quoi que ce soit.
Lis également tous les fichiers dans `/docs` pour avoir le contexte complet.

---

## C'est quoi Gwanur ?

Un jeu vidéo d'exploration et de puzzles coopératif local, jouable en split-screen vertical sur PC.
Deux joueurs, deux personnages, aucun combat. Uniquement de l'exploration et des puzzles.

**Ambiance :** Heroic fantasy médiéval, style Studio Ghibli / Anime semi-réaliste  
**Moteur :** Godot 4.6 (Forward Plus, 3D)  
**Langage :** GDScript  
**Résolution :** 1920×1080, 60fps, stretch canvas_items  
**Durée de jeu visée :** ~10 heures

---

## Les Personnages

| | Kael | Mira |
|---|---|---|
| Héritage | Magie elfique (nature) | Robustesse humaine |
| Équipement clé | Brassards de Sève, Corne d'Appel, Carnet | Grappin de Cuivre, Lanterne à Mémoire, Sac d'Alchimiste |
| Personnalité | Rêveur, contemplatif, lien à la nature | Déterminée, pragmatique, instinctive |

---

## Règles de Développement

### 🎮 Game Design
- Les puzzles ont TOUJOURS une solution de base accessible sans skills
- Les skills enrichissent l'expérience, ils ne bloquent jamais la progression
- Chaque zone a 3 niveaux de solution : base / 1 skill / 2 skills
- La coop est obligatoire — aucun puzzle ne se résout seul

### 🌿 Ambiance & Narration
- Zéro combat, jamais
- Ton Ghibli : doux, mélancolique, poétique
- La tension entre Kael et Mira est émotionnelle, pas violente
- Les PNJ ont de la mémoire — ils se souviennent des choix des joueurs

### 💻 Code
- Godot 4 uniquement, pas de Godot 3
- GDScript en priorité, C# uniquement si vraiment nécessaire
- Commenter le code en français
- Un fichier = une responsabilité claire
- Tester chaque feature en solo avant de tester en coop

### 📁 Organisation des fichiers
```
gwanur/
├── CLAUDE.md              ← ce fichier
├── docs/
│   ├── LORE.md            ← histoire, personnages, monde
│   ├── GAME_DESIGN.md     ← mécaniques, skills, moralité
│   ├── ART_DIRECTION.md   ← style visuel, palettes, pipeline
│   └── DECISIONS.md       ← toutes les décisions prises
├── scenes/
│   ├── characters/        ← Kael, Mira
│   ├── zones/             ← les 5 zones
│   ├── ui/                ← HUD, menus, split-screen
│   └── main.tscn          ← scène principale
├── scripts/
│   ├── characters/        ← logique des personnages
│   ├── puzzles/           ← systèmes de puzzles
│   ├── skills/            ← arbres de compétences
│   └── morality/          ← système de moralité
├── assets/
│   ├── models/            ← modèles 3D Kael & Mira
│   ├── textures/          ← textures et matériaux
│   ├── audio/             ← musiques et sons
│   └── fonts/             ← polices UI
└── README.md
```

---

## État Actuel du Projet

**Phase :** Zone 1 en cours — scripts de base fonctionnels, puzzles codés, polish et PNJ à finir.

**Scope :** Gwanur est un jeu **court et complet** — Zone 1 uniquement (~45 min). Deux joueurs obligatoires. Zéro combat. L'objectif est de **finir et publier**, puis recommencer un nouveau projet.

Ce qui existe :
- `scripts/characters/character_base.gd` — mouvement, gravité, interactions
- `scripts/characters/kael.gd` + `mira.gd` — skills puzzle (brassards, corne, grappin, lanterne)
- `scripts/puzzles/` — les 3 puzzles Zone 1 codés (porte double, oiseau, roue d'eau)
- `scripts/globals/` — GameManager + DialogueManager (AutoLoads)
- `scripts/zones/zone1.gd` — géométrie procédurale Zone 1
- `scenes/zones/zone1.tscn` — scène Zone 1
- `docs/` — LORE, GAME_DESIGN, ART_DIRECTION, DECISIONS complets

Ce qui reste à faire :
- PNJ avec dialogues (Vaenmor, Lira, Brennan)
- L'Aelith (l'arbre central) en décor + interaction
- Le grimoire d'Aelindra + choix de fin de zone
- La stèle du Pacte d'Aelric
- Split-screen (à restaurer — avait été retiré lors d'un pivot abandonné)
- Polish visuel et sonore

Consulte `docs/DECISIONS.md` pour le détail de toutes les décisions prises.

---

## Comment travailler avec moi

- **Toujours** lire CLAUDE.md + les fichiers docs/ en début de session
- **Toujours** mettre à jour DECISIONS.md après chaque décision importante
- Me rappeler le contexte si la session est longue
- Poser des questions avant de coder si quelque chose n'est pas clair dans le lore ou le game design
- Le développeur débute en Godot/GDScript — expliquer clairement chaque étape, pas de raccourcis, pas de patterns avancés sans explication
- Ne pas présupposer de connaissances sur les nœuds Godot, les signaux, ou l'architecture de scène
