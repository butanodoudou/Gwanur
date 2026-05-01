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

## À décider

- [ ] Les lettres d'Aldric — contenu de chacune
- [ ] Les PNJ de chaque zone — noms, rôles, dialogues
- [ ] L'antagoniste de la Zone 3 — qui est-il, quelle est sa motivation
- [ ] La mécanique exacte du Lac des Reflets
- [ ] Les détails du grand choix final Zone 5
- [ ] La musique — compositeur, style, instruments
- [ ] Le menu principal et l'UI
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

## 2026-04-25 — Setup technique du projet

### Version Godot
**Décision :** Godot 4.6 (non .NET, Standard)
**Raison :** Dernière version stable au moment du démarrage. On reste sur la version GDScript pure — pas de C#
**Impact :** Toute la doc et le code cible Godot 4.6 spécifiquement

---

### Renderer
**Décision :** Forward Plus (3D)
**Raison :** Le jeu est en 3D semi-réaliste — Forward Plus est le renderer 3D complet de Godot 4
**Impact :** Pas de Mobile ou Compatibility renderer. Pipeline artistique Meshy → Blender → Godot confirmé

---

### Résolution et framerate
**Décision :** 1920×1080, 60fps max, stretch `canvas_items` avec aspect `expand`
**Raison :** Standard PC, le stretch `expand` permet de s'adapter aux écrans différents sans déformer
**Impact :** Tous les éléments UI doivent être pensés pour le stretch expand

---

### Structure des dossiers assets
**Décision :** Le dossier `assets/` contient `models/`, `textures/`, `audio/`, `fonts/` — pas de `sprites/` ni de `tilesets/`
**Raison :** Le jeu est en 3D. Le README initial mentionnait des sprites et tilesets par erreur
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

## 2026-04-25 — Architecture technique des personnages

### Scripts des personnages
**Décision :** Un script de base `CharacterBase` gère le mouvement, la gravité et les interactions. `Kael` et `Mira` en héritent et ajoutent leurs skills propres.
**Raison :** Évite la duplication de code
**Impact :** `scripts/characters/character_base.gd`, `kael.gd`, `mira.gd`

---

### Contrôles
**Décision :** Joueur 1 (Kael) → clavier ZQSD + E + A + R. Joueur 2 (Mira) → manette (stick gauche + A/X/Y).
**Raison :** ZQSD standard AZERTY. La manette couvre tous les layouts de gamepad courants.
**Impact :** Input map définie dans `project.godot`

---

### Système de split-screen
**Décision :** Deux `SubViewport` (own_world_3d=false) dans un `HBoxContainer` plein écran via `CanvasLayer`.
**Raison :** Approche native Godot 4 pour le split-screen local
**Impact :** `scenes/main.tscn` restructuré

---

### Caméra follow
**Décision :** Script `camera_follow.gd` avec `offset: Vector3` et `lissage: float`. La cible est assignée par main.gd au démarrage.
**Raison :** Connexion par code plus propre que les NodePath cross-tree
**Impact :** `scripts/camera/camera_follow.gd`

---

### Placeholder des personnages
**Décision :** Kael et Mira utilisent une `CapsuleMesh` (r=0.3, h=1.8) comme modèle temporaire
**Raison :** Permet de tester mouvement et split-screen sans attendre les modèles finaux
**Impact :** `scenes/characters/kael.tscn` et `mira.tscn` — à remplacer quand les modèles sont prêts

---

## 2026-04-26 — Prototype Zone 1

### Deux manettes
**Décision :** Les deux joueurs utilisent des manettes (device 0 et device 1). Le clavier ZQSD reste en fallback.
**Raison :** La cible est des couples dont l'un n'est pas gamer — la manette est plus accessible et symétrique
**Impact :** Layout : stick gauche = déplacer, A = interagir, X = skill 1, Y = skill 2

---

### Géométrie procédurale pour le prototype
**Décision :** zone1.gd crée le décor en code via des BoxMesh/StaticBody3D colorés
**Raison :** Évite des .tscn trop lourds avant l'intégration des vrais modèles 3D
**Impact :** Zone 1 jouable immédiatement. Les blocs colorés seront remplacés par les assets Meshy/Blender

---

### Puzzles Zone 1
**Décision :** Trois puzzles définis et codés (porte double, oiseau, roue d'eau) + deux PNJ (Lira, Brennan) + grimoire avec choix de fin de zone
**Raison :** Couvre les trois structures coop : simultané / maintenir+agir / communication verbale
**Impact :** `scripts/puzzles/`, `scripts/npcs/pnj.gd`, `scenes/zones/zone1.tscn`

---

### Autoloads
**Décision :** GameManager et DialogueManager sont des AutoLoads
**Raison :** Accessibles depuis n'importe quel script sans référence explicite. Standard Godot 4
**Impact :** Enregistrés dans project.godot. `scripts/globals/`

---

## 2026-04-26 — Mécanique de la Lanterne

### Conditions d'activation des échos
**Décision :** La Lanterne révèle toujours des silhouettes floues. Pour que l'écho devienne net, Mira doit avoir réuni un contexte au préalable : parler à un témoin, trouver un objet lié, lire une inscription.
**Raison :** Évite que la lanterne soit trop facile. Crée un vrai loop d'exploration.
**Impact :** Les échos anciens nécessitent le skill "Mémoire Profonde" débloqué en progression

---

## 2026-04-26 — Ciblage automatique pour les skills

### Brassards de Sève
**Décision :** La liane pousse automatiquement vers la surface végétale la plus proche dans la direction de Kael. Pas de visée manuelle.
**Raison :** La cible est des couples avec un non-gamer. La visée manuelle crée de la frustration.
**Impact :** `kael.gd` détecte la surface végétale la plus proche dans un cône de 45°

### Grappin de Cuivre
**Décision :** Le grappin cible le point d'accroche le plus proche dans la direction de Mira (ciblage assisté).
**Raison :** Même raison que pour les Brassards
**Impact :** Les points d'accroche brillent légèrement pour indiquer leur disponibilité

---

## 2026-04-26 — Design Zone 2

### La Forêt Entrelacée — mécanique centrale
**Décision :** Zone 2 introduit "La Forêt Parle" — chaque joueur reçoit une information différente (Kael ressent / Mira voit). La communication verbale devient la mécanique principale.
**Raison :** Progression naturelle depuis Zone 1. La forêt devient un personnage actif.
**Impact :** Tous les puzzles de Zone 2 reposent sur l'échange verbal entre joueurs

### Le calme de Kael comme ressource
**Décision :** En Zone 2, la forêt ne répond aux Brassards que si Kael est immobile.
**Raison :** Crée une tension : Mira a besoin de lui maintenant, mais il doit s'arrêter
**Impact :** Nouveau type de puzzle : Kael en position fixe pendant que Mira gère l'environnement

---

## 2026-04-26 — Décor et pipeline d'assets

### Kit de modules pour la structure
**Décision :** Murs, sols et bâtiments construits avec Kenney Medieval Kit (CC0). Meshy AI pour les props uniques.
**Raison :** 90% des jeux indie sont faits ainsi. Kenney permet de démarrer vite.
**Impact :** `zone1.gd` désactivé quand les vrais assets arrivent. Assets dans `assets/models/environnement/`

### Végétation procédurale
**Décision :** `MultiMeshInstance3D` pour la végétation
**Raison :** Approche native Godot 4, performante, cohérente avec le style Ghibli
**Impact :** Un seul MultiMeshInstance3D par type de plante, configuré dans l'éditeur

---

## 2026-04-26 — Lore & Géopolitique

### Les trois nations
**Décision :**
- Royaume humain : **Arathos**
- Elfes du Nord : **Elarindë** (La Grande Sylve pour les humains)
- Elfes des Lisières : **Vaelindra**

**Raison :** Noms cohérents avec les cultures et les intentions narratives de chaque peuple
**Impact :** Toute la géopolitique et le lore du monde s'appuient sur cette nomenclature

---

### Les peuples lointains
**Décision :** Nains (derrière les montagnes) et Orques (de l'autre côté de l'océan) existent mais sont hors du conflit principal
**Raison :** Enrichit le monde sans alourdir le récit. Les Nains servent via leurs gravures anciennes dans les Ruines.
**Impact :** Présents dans le lore, absents du gameplay principal

---

### Aldric et Aelindra — héros fondateurs
**Décision :** Aldric et Aelindra n'étaient pas des gens ordinaires. Ils ont été les architectes du Pacte d'Aelric — lui comme émissaire d'Arathos, elle comme Tisserande de Vaelindra. Ils ont caché leur identité à leurs enfants pour les protéger du poids de cette légende.
**Raison :** Transforme l'arc de révélation en découverte progressive d'un héritage héroïque. Donne un sens profond aux lettres d'Aldric.
**Impact :** Toute la structure des révélations Zone 1 à 5. Les jumeaux découvrent qui ils sont réellement.

---

### Le Pacte d'Aelric
**Décision :** L'accord de paix s'appelle le **Pacte d'Aelric** — fusion des noms Aelindra et Aldric. Un cessez-le-feu et une promesse de paix après plusieurs années de guerre totale.
**Raison :** Le nom est à la fois un secret et une révélation. Les jumeaux entendent ce nom depuis le début sans faire le lien. Le choc arrive en Zone 5.
**Impact :** Stèle gravée à l'entrée des Terres Grises dès Zone 1. Révélation en Zone 5.

---

### L'antagoniste Zone 3
**Décision :** Ancien général de la Grande Sylve qui n'a jamais accepté le Pacte d'Aelric. Sa rancœur envers Aldric et Aelindra est légitime — il défend une logique sur le temps long, pas une haine aveugle.
**Raison :** Un antagoniste qui a raison est plus fort narrativement qu'un villain classique
**Impact :** Nom et détails à définir en session ultérieure

---

### Zone 1 — Structure narrative consolidée
**Décision :** Zone 1 plante toutes les tensions sans les résoudre. Cinématique muette, village qui cache un secret, premier puzzle de friction entre les jumeaux, stèle du Pacte d'Aelric à la frontière.
**Raison :** La Zone 1 doit créer le malaise, l'attachement et la curiosité — pas expliquer.
**Impact :** Acte 0 (cinématique), Acte 1 (village), Acte 2 (friction / pont), Acte 3 (frontière)

---

### Vaenmor — L'Ancien de Sylvara
**Décision :** Le PNJ clé de Zone 1 s'appelle **Vaenmor** (honorifique vaelindrien : "barbe cendre-vieux"). Son vrai nom a été oublié. Interaction optionnelle, caché parmi 6 PNJ de bruit inutiles. Puzzle coop optionnel au pied de l'Aelith s'il est abordé.
**Raison :** Récompense l'exploration sans punir ceux qui passent. La perle cachée dans le bruit.
**Impact :** Donne le fragment de lettre 1 et un raccourci vers Zone 2 si le puzzle est résolu

---

---

## 2026-05-02 — Pivot majeur : RPG solo avec combats

### Genre
**Décision :** Le jeu passe de "coop puzzle obligatoire" à **RPG solo avec combats**, jouable à 1 ou 2 joueurs en mode drop-in/drop-out façon Fable 2.
**Raison :** Le format puzzle-coop obligatoire limitait trop le public. Le lore héroïc fantasy se prête naturellement au combat.
**Impact :** Refonte du gameplay central. Le lore, les personnages et les 5 zones restent identiques.

---

### Mode solo
**Décision :** En solo, le joueur choisit entre Kael ou Mira. L'autre personnage est contrôlé par une **IA compagnon**.
**Raison :** Cohérent avec Fable 2. Les deux personnages restent présents narrativement — la tension Kael/Mira est conservée.
**Impact :** Nécessite un système d'IA compagnon (follow + combat basique + ordres simples).

---

### Mode coop (Fable 2)
**Décision :** Le joueur 2 peut rejoindre ou quitter à tout moment sans interrompre le jeu. Quand il quitte, l'IA reprend.
**Raison :** Fable 2 est la référence exacte voulue. Drop-in/drop-out fluide.
**Impact :**
- **Plus de split-screen** → caméra partagée dynamique (zoom out quand les joueurs s'éloignent)
- Le joueur 2 est "invité" : HUD simplifié, pas d'accès à la carte
- Si les joueurs sont trop loin : le joueur 2 est téléporté près du joueur 1

---

### Combat
**Décision :** Combats en **temps réel action RPG** (pas tour par tour). Style Tales of Arise / Fable.
**Raison :** Cohérent avec le lore héroïc fantasy et l'ambiance dynamique voulue.
**Impact :**
- Kael : mage nature — sorts de lianes, vent, lumière. Corps-à-corps faible.
- Mira : guerrière physique — grappin offensif, bombes alchimiques, corps-à-corps fort.
- Système HP/mana/stamina à créer
- Ennemis à définir par zone

---

### Puzzles
**Décision :** Les puzzles restent mais deviennent **optionnels / secondaires**. Ce ne sont plus des bloquants de progression.
**Raison :** Dans un RPG solo avec combat, bloquer la progression sur un puzzle coop obligatoire serait frustrant en solo.
**Impact :** Les puzzles deviennent des quêtes secondaires ou des accès à du lore/équipement bonus.

---

### Caméra
**Décision :** Caméra partagée unique, **orbitale + zoom dynamique**. Plus de SubViewport split-screen.
**Raison :** Fable 2 n'a pas de split-screen. La caméra suit les deux personnages et zoome out si nécessaire.
**Impact :** Refonte de main.tscn et camera_follow.gd. Les SubViewports sont supprimés.

---

## À décider

- [ ] Les lettres d'Aldric — contenu de chacune des 5 lettres
- [ ] L'antagoniste Zone 3 — nom, backstory détaillé, dialogues
- [ ] La mécanique exacte du Lac des Reflets
- [ ] Le grand choix final Zone 5
- [ ] Les PNJ des Zones 2, 3, 4 et 5
- [ ] Le nom du village de Sylvara
- [ ] La musique — compositeur, style, instruments
- [ ] Le menu principal et l'UI
- [ ] Types d'ennemis par zone
- [ ] Système de stats (HP, mana, stamina, XP)
- [ ] Arbre de compétences combat (distinct des skills narratifs)