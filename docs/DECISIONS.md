# 📋 Gwanur — Journal des Décisions

Ce fichier centralise toutes les décisions importantes prises sur le projet.
À mettre à jour après chaque session de travail ou décision significative.

Format :
```
## [DATE] — Sujet
**Décision :** Ce qui a été décidé
**Raison :** Pourquoi ce choix
**Impact :** Ce que ça change
```

---

## Session 1 — Fondations du projet

### Nom du projet
**Décision :** Le projet s'appelle **Gwanur**  
**Raison :** Mot Sindarin (elfique Tolkien) signifiant "les jumeaux". Court, mémorable, cohérent avec le lore  
**Impact :** Nom du repo, des fichiers, de l'organisation

---

### Genre & Plateforme
**Décision :** Jeu d'exploration et puzzles coop local, PC, split-screen vertical  
**Raison :** Accessible, cohérent avec l'ambiance cocooning voulue  
**Impact :** Architecture technique, pas de serveur réseau nécessaire

---

### Pas de combat
**Décision :** Zéro combat dans le jeu, uniquement des puzzles  
**Raison :** Cohérent avec l'ambiance Ghibli et le ton mélancolique doux  
**Impact :** Pas de système de combat à développer, focus total sur les puzzles

---

### Moteur de jeu
**Décision :** Godot 4 avec GDScript  
**Raison :** Gratuit, open-source, split-screen natif, bonne communauté indie  
**Impact :** Toute la codebase en GDScript, pas d'Unity ou Unreal

---

### Personnages
**Décision :** Deux jumeaux demi-elfes adolescents, Kael (16 ans) et Mira (16 ans)  
**Raison :** La dualité des personnages porte tout le game design et la narration  
**Impact :** Deux arbres de compétences distincts, deux curseurs de moralité

---

### Héritage des personnages
**Décision :** Kael hérite de la magie elfique, Mira hérite de la robustesse humaine  
**Raison :** Contraste naturel qui rend la coop obligatoire et narrativement cohérente  
**Impact :** Équipements et skills pensés autour de cette dualité

---

### Style visuel
**Décision :** 3D semi-réaliste style anime (Genshin Impact / Tales of Arise) avec ambiance Ghibli  
**Raison :** Le développeur vise la 3D, le style anime correspond à la palette chaude voulue  
**Impact :** Pipeline Meshy → VRoid → Blender → Mixamo → Godot

---

### Palette de couleurs
**Décision :** Tons chauds dominants — auburn, doré miel, terre, rouille, beige doré  
**Raison :** Cohérent avec l'ambiance médiévale chaleureuse et le style Ghibli  
**Impact :** Toute la direction artistique, tenues des personnages, environnements

---

### Structure narrative — La mère
**Décision :** Aelindra est la Tisserande — gardienne de l'équilibre entre les peuples. Elle a caché sa vraie identité pour vivre une vie normale avec leur père humain  
**Raison :** Ressort narratif fort, cohérent avec le thème de l'identité cachée  
**Impact :** Toute la structure narrative des 5 zones

---

### Le père
**Décision :** Aldric est mort 2 ans avant le début du jeu. Il savait tout sur Aelindra depuis le début et a choisi de l'aimer quand même  
**Raison :** Sa mort crée une douleur permanente. Son amour inconditionnel est le modèle que les jumeaux cherchent inconsciemment  
**Impact :** Présent via des lettres dans le Carnet de Kael, des échos dans la Lanterne de Mira

---

### Système de progression
**Décision :** Skills RPG débloqués via des choix narratifs à la fin de chaque zone  
**Raison :** Lier la progression au récit, pas au grinding. Favorise la rejouabilité  
**Impact :** Deux arbres de compétences (Kael / Mira), plusieurs chemins possibles

---

### Règle des puzzles
**Décision :** Chaque puzzle a toujours 3 niveaux — solution de base / 1 skill / 2 skills  
**Raison :** Les skills ne bloquent jamais la progression, ils enrichissent l'expérience  
**Impact :** Tout le level design doit respecter cette règle

---

### Système de moralité
**Décision :** Chaque jumeau a son propre curseur de moralité indépendant (Kael : Instinct↔Raison / Mira : Méfiance↔Confiance)  
**Raison :** Renforcer la dualité des personnages, rendre les PNJ réactifs à chacun  
**Impact :** Dialogues différenciés, fins multiples, puzzle social avec certains PNJ

---

### Structure du jeu
**Décision :** 5 zones, ~10 heures de jeu total. Pas de système de saisons.  
**Raison :** Les saisons complexifiaient trop le développement pour un premier jeu  
**Impact :** Un jeu complet de A à Z, plus réaliste à développer

---

### Les zones
**Décision :**
1. Village des Lisières (1h30)
2. Forêt Entrelacée (2h)
3. Ruines de l'Entre-Deux (2h30)
4. Lac des Reflets (2h)
5. Cœur des Terres Grises (2h)

**Raison :** Progression narrative et émotionnelle cohérente  
**Impact :** Structure du level design et de la narration

---

### Ton de la fin
**Décision :** Mélancolie douce — comme après un Ghibli  
**Raison :** Cohérent avec l'ADN émotionnel du jeu  
**Impact :** Aelindra part sans mourir, les jumeaux restent ensemble, les Terres Grises refleurissent

---

---

## 2026-04-25 — Setup technique du projet

### Version Godot
**Décision :** Godot 4.6 (non .NET, Standard)  
**Raison :** Dernière version stable au moment du démarrage. On reste sur la version GDScript pure — pas de C#  
**Impact :** Toute la doc et le code cible Godot 4.6 spécifiquement

---

### Renderer
**Décision :** Forward Plus (3D)  
**Raison :** Le jeu est en 3D semi-réaliste — Forward Plus est le renderer 3D complet de Godot 4, nécessaire pour les effets de lumière et l'ambiance Ghibli  
**Impact :** Pas de Mobile ou Compatibility renderer. Pipeline artistique Meshy → Blender → Godot confirmé

---

### Résolution et framerate
**Décision :** 1920×1080, 60fps max, stretch `canvas_items` avec aspect `expand`  
**Raison :** Standard PC, le stretch `expand` permet de s'adapter aux écrans différents sans déformer  
**Impact :** Tous les éléments UI doivent être pensés pour le stretch expand

---

### Structure des dossiers assets
**Décision :** Le dossier `assets/` contient `models/`, `textures/`, `audio/`, `fonts/` — pas de `sprites/` ni de `tilesets/`  
**Raison :** Le jeu est en 3D. Le README initial mentionnait des sprites et tilesets par erreur (héritage d'un template 2D). On supprime cette confusion  
**Impact :** Pipeline artistique 3D exclusivement — aucun tilemap 2D prévu

---

### Langue du code
**Décision :** Commentaires en français, noms de variables et fonctions en anglais snake_case  
**Raison :** Le développeur est francophone. Les noms en anglais restent universels et compatibles avec Godot  
**Impact :** Ex. : `func move_player():` avec commentaire `# Déplace le joueur selon l'input`

---

### Scaffold initial
**Décision :** Le projet démarre avec `scenes/main.tscn` (Node2D vide) comme scène principale  
**Raison :** Point d'entrée minimal avant de construire la structure complète  
**Impact :** La scène principale sera remplacée ou enrichie quand les personnages et la caméra seront prêts

---

---

## 2026-04-25 — Architecture technique des personnages

### Scripts des personnages — héritage CharacterBase → Kael / Mira
**Décision :** Un script de base `CharacterBase` (extends CharacterBody3D) gère le mouvement, la gravité et les interactions. `Kael` et `Mira` en héritent et ajoutent leurs skills propres.  
**Raison :** Évite la duplication de code. Le mouvement est identique pour les deux — seuls les skills diffèrent. Facile à comprendre pour un débutant.  
**Impact :** `scripts/characters/character_base.gd`, `kael.gd`, `mira.gd`

---

### Contrôles
**Décision :** Joueur 1 (Kael) → clavier ZQSD + E (interagir) + A (skill1) + R (skill2). Joueur 2 (Mira) → manette (stick gauche + A/X/Y).  
**Raison :** ZQSD est le standard pour les claviers AZERTY français. La manette couvre tous les layouts de gamepad courants (Xbox/PS).  
**Impact :** Input map définie dans `project.godot` — actions nommées `joueur1_*` et `joueur2_*`

---

### Système de split-screen
**Décision :** Deux `SubViewport` (own_world_3d=false) dans un `HBoxContainer` plein écran via `CanvasLayer`. Chaque SubViewport a sa propre `Camera3D` qui suit son personnage.  
**Raison :** `own_world_3d=false` permet aux deux viewports de rendre le même monde 3D depuis deux caméras différentes — c'est l'approche native Godot 4 pour le split-screen local.  
**Impact :** `scenes/main.tscn` restructuré. Connexion caméra↔personnage faite par code dans `scripts/main.gd`

---

### Caméra follow
**Décision :** Script `camera_follow.gd` (extends Camera3D) avec `offset: Vector3` et `lissage: float`. La cible est assignée par main.gd au démarrage (pas en éditeur).  
**Raison :** Les caméras sont dans les SubViewports et les personnages dans le Monde — deux branches d'arbre différentes. La connexion par code est plus propre que les NodePath cross-tree.  
**Impact :** `scripts/camera/camera_follow.gd`

---

### Placeholder des personnages
**Décision :** Kael et Mira utilisent une `CapsuleMesh` (r=0.3, h=1.8) comme modèle temporaire jusqu'à l'intégration des vrais assets 3D.  
**Raison :** Permet de tester mouvement et split-screen sans attendre les modèles finaux.  
**Impact :** `scenes/characters/kael.tscn` et `mira.tscn` — à remplacer quand les modèles Meshy/Blender sont prêts

---

## 2026-04-26 — Prototype Zone 1

### Deux manettes
**Décision :** Les deux joueurs utilisent des manettes (device 0 et device 1). Le clavier ZQSD reste en fallback pour le développeur seul.  
**Raison :** La cible est des couples dont l'un n'est pas gamer — la manette est plus accessible et symétrique.  
**Impact :** project.godot mis à jour. Layout : stick gauche = déplacer, A = interagir, X = skill 1, Y = skill 2.

---

### Géométrie procédurale pour le prototype
**Décision :** zone1.gd crée le décor (sol, murs, maisons) en code via des BoxMesh/StaticBody3D colorés.  
**Raison :** Évite des .tscn trop lourds avant l'intégration des vrais modèles 3D. Facile à modifier.  
**Impact :** Zone 1 jouable immédiatement. Les blocs colorés seront remplacés par les assets Meshy/Blender.

---

### Puzzles Zone 1
**Décision :** Trois puzzles définis et codés (porte double, oiseau, roue d'eau) + deux PNJ (Lira, Brennan) + grimoire avec choix de fin de zone.  
**Raison :** Couvre les trois structures coop : simultané / maintenir+agir / communication verbale.  
**Impact :** `scripts/puzzles/`, `scripts/npcs/pnj.gd`, `scenes/zones/zone1.tscn`

---

### Autoloads
**Décision :** GameManager (état global : flags, moralité, choix) et DialogueManager (CanvasLayer : affiche les dialogues PNJ) sont des AutoLoads.  
**Raison :** Accessibles depuis n'importe quel script sans référence explicite. Standard Godot 4.  
**Impact :** Enregistrés dans project.godot. `scripts/globals/`

---

## 2026-04-26 — Mécanique de la Lanterne

### Conditions d'activation des échos
**Décision :** La Lanterne à Mémoire révèle toujours des silhouettes floues. Pour que l'écho devienne net et utilisable, Mira doit avoir réuni un "contexte" au préalable : parler à un témoin, trouver un objet lié à la scène, lire une inscription.  
**Raison :** Évite que la lanterne soit trop facile (scanner le niveau pour trouver toutes les solutions). Crée un vrai loop d'exploration : indice → retour à l'endroit → compréhension → puzzle.  
**Impact :** Les échos proches/récents = accessibles avec contexte. Les échos anciens = nécessitent le skill "Mémoire Profonde" débloqué en progression.

---

## 2026-04-26 — Ciblage automatique pour les skills

### Brassards de Sève — ciblage auto
**Décision :** La liane pousse automatiquement vers la surface végétale la plus proche dans la direction de Kael. Pas de visée manuelle.  
**Raison :** La cible est des couples avec un non-gamer. La visée manuelle crée de la frustration pour les joueurs peu habitués aux contrôles. La version automatique reste suffisamment précise pour les puzzles de Zone 1 et 2.  
**Impact :** `kael.gd` détecte la surface végétale la plus proche dans un cône de 45° devant le joueur. Le ciblage manuel pourrait être introduit comme skill avancé dans Zone 3+.

### Grappin de Cuivre — ciblage assisté
**Décision :** Le grappin cible le point d'accroche le plus proche dans la direction de Mira (ciblage assisté, pas manuel).  
**Raison :** Même raison que pour les Brassards. La visée libre peut frustrer un partenaire non-gamer.  
**Impact :** Les points d'accroche brillent légèrement pour indiquer qu'ils sont disponibles. Un seul bouton = une seule action claire.

---

## 2026-04-26 — Design Zone 2

### La Forêt Entrelacée — mécanique centrale
**Décision :** Zone 2 introduit "La Forêt Parle" — chaque joueur reçoit une information *différente* de la forêt (Kael ressent / Mira voit). Ni l'un ni l'autre ne peut résoudre seul. La communication verbale entre joueurs devient la mécanique principale.  
**Raison :** Progression naturelle depuis Zone 1 où l'environnement était passif. Zone 2 fait de la forêt un personnage actif qui teste les jumeaux.  
**Impact :** Tous les puzzles de Zone 2 reposent sur l'échange d'informations verbales entre les joueurs, pas seulement sur les actions.

### Le calme de Kael comme ressource
**Décision :** En Zone 2, la forêt ne répond aux Brassards de Kael que s'il est immobile. S'il court, les plantes se referment.  
**Raison :** Crée une tension naturelle : Mira a besoin de lui *maintenant*, mais lui doit *s'arrêter* pour activer quelque chose. Les joueurs doivent négocier le timing — c'est un puzzle de coordination, pas d'action.  
**Impact :** Introduce un type de puzzle nouveau : Kael en position fixe pendant que Mira gère l'environnement autour de lui.

### Puzzles Zone 2 — trois structures
**Décision :** Porte des Deux Cœurs (sync positionnelle), Rayon Brisé (coordination spatiale + craft), Deux Mémoires (communication verbale pure + révélation lore).  
**Raison :** Progression en complexité. Le troisième puzzle est le plus narrativement fort — il révèle le titre d'Aelindra via le Gardien.  
**Impact :** Zone 2 introduit le Sac d'Alchimiste de Mira (premier craft : éclat de cuivre poli) et le calme de Kael comme condition de jeu.

---

## 2026-04-26 — Décor et pipeline d'assets

### Kit de modules pour la structure
**Décision :** Les murs, sols et bâtiments sont construits avec un kit de modules réutilisables (Kenney Medieval Kit — CC0 gratuit). Modules placés dans l'éditeur Godot comme des Lego. Meshy AI pour les props uniques (objets spécifiques, détails narratifs).  
**Raison :** 90% des jeux indie sont faits ainsi. Kenney permet de démarrer vite sans attendre les vrais modèles. Séparation claire entre la géométrie de collision (dans les scripts, permanente) et le visuel (remplaçable).  
**Impact :** `zone1.gd` désactivé quand les vrais assets arrivent. Les scripts de puzzles et Area3D ne changent pas. Assets dans `assets/models/environnement/`.

### Végétation procédurale
**Décision :** `MultiMeshInstance3D` pour placer des milliers d'éléments de végétation (herbe, petites plantes) sans impact sur les performances.  
**Raison :** Approche native Godot 4, performante, cohérente avec le style Ghibli qui demande beaucoup de verdure.  
**Impact :** Pas de végétation un-par-un dans la scène. Un seul MultiMeshInstance3D par type de plante, configuré dans l'éditeur.

---

## À décider

- [ ] Les lettres d'Aldric — contenu de chacune
- [ ] Les PNJ de chaque zone — noms, rôles, dialogues
- [ ] L'antagoniste de la Zone 3 — qui est-il, quelle est sa motivation
- [ ] La mécanique exacte du Lac des Reflets
- [ ] Les détails du grand choix final Zone 5
- [ ] La musique — compositeur, style, instruments
- [ ] Le menu principal et l'UI
