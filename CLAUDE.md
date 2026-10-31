# 🌿 Gwanur — Briefing Claude Code

Bienvenue sur le projet **Gwanur**. Lis ce fichier en entier avant de faire quoi que ce soit.
Lis également tous les fichiers dans `/docs` pour avoir le contexte complet.

---

## C'est quoi Gwanur ?

Un jeu vidéo d'exploration et de puzzles coopératif local, jouable en split-screen vertical sur PC.
**Sylvara, le village de la Zone 1, est bâti DANS le tronc creux de l'Aelith** — l'arbre est si vaste
que le village tient dans sa cavité, protégé par une paroi de bois de 62 m. Voir `docs/DECISIONS.md`.
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
├── CLAUDE.md               ← ce fichier
├── docs/
│   ├── LORE.md             ← histoire, personnages, monde
│   ├── GAME_DESIGN.md      ← mécaniques, skills, moralité
│   ├── ART_DIRECTION.md    ← style visuel, palettes, pipeline
│   ├── DECISIONS.md        ← toutes les décisions prises
│   └── archive/            ← designs abandonnés (pivot RPG) — NE PAS implémenter
├── scenes/
│   ├── characters/         ← kael.tscn, mira.tscn
│   ├── zones/              ← zone1.tscn
│   ├── ui/                 ← HUD (à venir)
│   ├── main.tscn           ← scène de jeu (split-screen)
│   ├── menu_principal.tscn ← scène de démarrage
│   └── test_mecanique.tscn ← banc de test : sol plat, Kael + Mira, pas de puzzles
├── scripts/
│   ├── characters/         ← character_base.gd, kael.gd, mira.gd
│   ├── puzzles/            ← les 3 puzzles Zone 1
│   ├── npcs/               ← pnj.gd (PNJ générique piloté par données)
│   ├── zones/              ← zone1.gd (géométrie + orchestration) + decor_village.gd
│   ├── globals/            ← GameManager, DialogueManager, InteractionManager (AutoLoads)
│   ├── interaction/        ← point_interaction.gd (à attacher aux Area3D du décor)
│   ├── camera/             ← camera_follow.gd
│   ├── ui/                 ← menu_principal.gd, hud_joueur.gd
│   └── main.gd             ← câblage caméras ↔ personnages
├── tools/
│   ├── tests/              ← tests headless (voir l'en-tête de chaque fichier)
│   ├── capture_zone1.tscn  ← photographie la zone sous plusieurs angles
│   ├── vitrine.tscn        ← aligne des .glb côte à côte pour les juger
│   ├── blender_commun.py   ← palette, primitives et export partagés
│   ├── gen_maison.py       ← maison_a / maison_b / moulin
│   ├── gen_arbres.py       ← 4 essences + buisson
│   ├── gen_aelith_v2.py    ← la paroi et la canopée de l'Aelith
│   └── gen_personnages.py  ← Kael et Mira
│   └── *.py                ← scripts de génération/retouche d'assets
├── assets/
│   ├── models/             ← modèles 3D (environnement, personnages)
│   ├── audio/              ← musiques et sons
│   └── fonts/              ← polices UI
└── README.md
```

> Pas de dossier `skills/` ni `morality/` : la moralité est portée par
> `GameManager` (deux curseurs + la progression Zone 1), et les arbres de
> compétences ne sont pas implémentés — hors scope Zone 1.

---

## État Actuel du Projet

**Phase :** Zone 1 jouable de bout en bout — il reste le polish (UI, son, visuel).

**Scope :** Gwanur est un jeu **court et complet** — Zone 1 uniquement (~45 min). Deux joueurs obligatoires. Zéro combat. L'objectif est de **finir et publier**, puis recommencer un nouveau projet.

Ce qui existe :
- `scripts/characters/` — `character_base.gd` (mouvement, gravité, interactions) + `kael.gd` / `mira.gd` (brassards, corne, grappin, lanterne)
- `scripts/puzzles/` — les 3 puzzles Zone 1 (porte double, oiseau, roue d'eau)
- `scripts/npcs/pnj.gd` — Vaenmor, Lira, Brennan + les 6 villageois de bruit
- `scripts/globals/` — GameManager (moralité, progression) + DialogueManager (AutoLoads)
- `scripts/zones/zone1.gd` — géométrie procédurale + stèle du Pacte + grimoire et choix de fin de zone
- `scripts/zones/decor_village.gd` — décor du village (maisons .glb, forêt, chemins, props, lanternes) — sans collision, sauf les troncs
- `assets/models/environnement/` — maisons, arbres, paroi et canopée de l'Aelith (tous générés par les scripts `tools/gen_*.py`)
- `assets/models/personnages/` — `kael.glb`, `mira.glb` (sans squelette : ils glissent)
- `scenes/main.tscn` — split-screen vertical opérationnel
- `scenes/menu_principal.tscn` — scène de démarrage (Commencer / Quitter)
- `docs/` — LORE, GAME_DESIGN, ART_DIRECTION, DECISIONS complets

**Règle d'or pour l'input :** un seul système lit le bouton "interagir" —
`InteractionManager`. Un nouvel objet interactif ne doit **jamais** écouter
l'input lui-même. Pour un élément du décor, attache le script `PointInteraction`
à son `Area3D` et connecte son signal `active` : tout le reste est automatique
(prompt dans le HUD, enregistrement, désenregistrement).

Ajouté pendant la finition (2026-10-30, branche `feat/finition-zone1`) :
- Flux complet : intro (Acte 0) → jeu → fin selon le choix du grimoire → crédits → menu ; menu pause ; deux manettes
- `scripts/globals/audio_manager.gd` (4ᵉ AutoLoad) + `assets/audio/`, générés par `tools/gen_audio.py` (Python de Blender)
- PNJ modélisés (`tools/gen_pnj.py`), props des puzzles (`tools/gen_props.py`), lumière d'heure dorée
- `scripts/ui/textes_narration.gd` : tous les textes d'intro, de fin et de crédits
- `tools/tests/test_parcours_complet` : joue la Zone 1 entière
- Équipe d'agents : `.claude/equipe.md` + `.claude/agents/` (locaux, non versionnés)

Ce qui reste à faire :
- Faire tourner toute la batterie de tests sur la branche fusionnée, puis corriger ce qu'elle révèle
- Le nom dans les crédits, et ce qu'il y a de l'autre côté du pont du Puzzle 3
- Export Windows, puis playtest à deux manettes

Rendu et animation (2026-10-31) — cible visuelle **Breath of the Wild** :
- `scripts/rendu/stylisation.gd` convertit TOUS les matériaux en toon au chargement : un nouveau modèle n'a rien à faire de spécial. Feuillage = matériau dont le nom contient « feuill ».
- `scripts/zones/herbe.gd` (herbe au vent), `shaders/` (toon, sol, terre, herbe, ciel, rayons de lumière)
- Végétation : pack CC0 Quaternius dans `assets/models/vegetation/` — toute nouvelle source d'assets doit être tracée dans `LICENCES.md`
- Kael, Mira et les PNJ ont un squelette et des animations (`tools/animer_personnages.py`, appelé par `gen_personnages.py` / `gen_pnj.py`), pilotés par un AnimationTree construit dans `character_base.gd`

Consulte `docs/DECISIONS.md` pour le détail de toutes les décisions prises.
⚠️ `docs/archive/` contient des designs **abandonnés** (combat, RPG solo) — ne jamais s'en servir comme référence.

---

## Comment travailler avec moi

- **Toujours** lire CLAUDE.md + les fichiers docs/ en début de session
- **Toujours** mettre à jour DECISIONS.md après chaque décision importante
- Me rappeler le contexte si la session est longue
- Poser des questions avant de coder si quelque chose n'est pas clair dans le lore ou le game design
- Le développeur débute en Godot/GDScript — expliquer clairement chaque étape, pas de raccourcis, pas de patterns avancés sans explication
- Ne pas présupposer de connaissances sur les nœuds Godot, les signaux, ou l'architecture de scène
