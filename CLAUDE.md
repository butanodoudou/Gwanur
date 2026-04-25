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

**Phase :** Initialisation — scaffold posé, documentation complète, aucun script encore écrit.

Ce qui existe :
- `scenes/main.tscn` — scène principale vide (Node2D)
- `docs/` — LORE, GAME_DESIGN, ART_DIRECTION, DECISIONS complets
- `project.godot` — configuré (nom, résolution, scène principale, fps)

Ce qui reste à faire :
- Scènes et scripts des personnages (Kael, Mira)
- Input map (Joueur 1 clavier, Joueur 2 manette)
- Système de split-screen
- Premier puzzle de la Zone 1

Consulte `docs/DECISIONS.md` pour le détail des décisions prises.

---

## Comment travailler avec moi

- **Toujours** lire CLAUDE.md + les fichiers docs/ en début de session
- **Toujours** mettre à jour DECISIONS.md après chaque décision importante
- Me rappeler le contexte si la session est longue
- Poser des questions avant de coder si quelque chose n'est pas clair dans le lore ou le game design
- Le développeur débute en Godot/GDScript — expliquer clairement chaque étape, pas de raccourcis, pas de patterns avancés sans explication
- Ne pas présupposer de connaissances sur les nœuds Godot, les signaux, ou l'architecture de scène
