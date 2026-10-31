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

> ⚠️ Décision **révisée le 2026-05-03** : le scope est réduit à la Zone 1 uniquement.
> Les zones 2 à 5 restent documentées comme vision future.

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

> ⚠️ Décision **révisée le 2026-05-03** : seule la Zone 1 est développée (~45 min).

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

> 📌 Zone 2 n'est plus développée (scope réduit à Zone 1 le 2026-05-03).
> Ces décisions restent documentées comme vision future.

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

## 2026-05-02 — Pivot majeur : RPG solo avec combats

> ⚠️ **Pivot entièrement abandonné le 2026-05-03.** Conservé ici comme trace de
> réflexion et matière pour un futur projet. Rien de cette section n'est
> implémenté dans Gwanur. Design détaillé archivé dans `docs/archive/`.

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

## 2026-05-03 — Inspiration combat : Fable 1

> ⚠️ Même statut que la section précédente : **abandonné**, conservé pour un futur projet.

### Fable 1 comme référence principale du combat
**Décision :** Le système de combat s'inspire principalement de **Fable 1** (2004) pour la structure et le ressenti, en complément de Fable 2 pour le coop.
**Raison :** Fable 1 propose un combat temps réel lisible, satisfaisant et accessible — 3 boutons clairs, attaques chargées, lock-on automatique. Le public cible (couples avec un non-gamer) en bénéficie directement. Les 3 écoles de Fable (Strength / Skill / Will) mappent naturellement sur Kael et Mira.
**Impact :**
- Kael = école **Will** : sorts de nature (lianes, vent, lumière), corps-à-corps faible
- Mira = écoles **Strength + Skill** : mêlée lourde + grappin offensif/bombes
- Attaques chargées (maintenir le bouton), lock-on automatique (LT), combo multiplier XP
- XP séparé par discipline (comme Fable 1) — Kael monte sa Will, Mira monte Strength et Skill indépendamment

---

### L'équilibre Fable 1 / ambiance Ghibli
**Décision :** Le combat doit rester satisfaisant sans jamais être violent ou stressant. Pas de mort brutale, pas de gore.
**Raison :** L'ADN du jeu est Ghibli — doux, poétique. Le combat doit s'intégrer à cette ambiance, pas la trahir.
**Impact :**
- Ennemis vaincus : disparaissent dans la lumière ou se dissolvent dans la nature (pas de corps)
- HP à 0 : le personnage tombe mais peut être relevé par son compagnon (co-revive, 5s de fenêtre)
- Lock-on activé par défaut (accessible) — les non-gamers n'ont pas à viser
- Pas de one-shot : les ennemis étourdissent, knockback, jamais de dégâts absurdes

---

## 2026-05-03 — Repivot : retour au puzzle coop, scope Zone 1 uniquement

### Décision finale de scope
**Décision :** Gwanur redevient un **jeu de puzzles coop local, deux joueurs obligatoires**. Zéro combat. Scope réduit à la **Zone 1 uniquement** (~45 min), finie et publiable.
**Raison :** L'objectif est de **finir un jeu complet**. Le scope RPG/combat était trop large pour un premier projet solo. Le lore, les personnages, et le design Zone 1 sont déjà solides — on les exploite jusqu'au bout.
**Impact :**
- Le système de combat (Fable 1) est abandonné pour ce jeu — documenté en DECISIONS pour le prochain projet
- Le drop-in/drop-out coop est abandonné — deux joueurs obligatoires dès le départ
- L'IA compagnon est abandonnée
- Les zones 2 à 5 passent en "vision future" — non développées maintenant

---

### Caméra — retour au split-screen
**Décision :** On revient au **split-screen vertical** (deux SubViewports, `own_world_3d = false`), qui était l'approche originale avant le pivot RPG.
**Raison :** Deux joueurs obligatoires = split-screen naturel. Cohérent avec le design puzzle coop.
**Impact :** Restaurer la configuration split-screen dans `main.tscn`. La caméra orbitale partagée (pivot RPG) est abandonnée.

---

## 2026-05-24 — Finition Zone 1

### Nom de la mère — "Aelindra" partout
**Décision :** "Elara" (erreur de cohérence) corrigé en "Aelindra" dans tous les fichiers.
**Impact :** Dialogues de Lira, Brennan et le grimoire sont maintenant cohérents avec le lore.

### PNJ de bruit — 6 villageois ajoutés
**Décision :** Marnen, Soraï, Eldwen, Tovan, Nyssil, Caeryn — placés autour des maisons.
**Raison :** Village vivant. Vaenmor isolé parmi 3 PNJ était trop évident.
**Impact :** Caeryn hint le Puzzle 1 ("deux cœurs bien accordés"), Soraï observe l'Aelith changer, Nyssil humanise le contexte géopolitique.

### Stèle du Pacte d'Aelric — interactive
**Décision :** ZoneStele Area3D déclenche l'inscription une seule fois à l'approche.
**Raison :** Premier indice explicite que "Aelric" = Aelindra + Aldric.
**Impact :** Handler dans zone1.gd avec flag `_stele_lue`.

### DialogueManager — avance sur bouton + signal dialogue_fini
**Décision :** Avance sur joueur1_interagir ou joueur2_interagir. DELAI_MIN=0.6s, DELAI_AUTO=5s. Signal `dialogue_fini` émis à la fermeture.
**Raison :** L'auto-avance à 3.5s retirait le contrôle au joueur.
**Impact :** Universel sur tous les dialogues du jeu.

### Lettre d'Aldric — livrée par Vaenmor
**Décision :** Vaenmor livre la lettre 1 dans sa conversation (14 lignes). Aldric savait, a choisi d'aimer quand même.
**Raison :** Naturel — Vaenmor dit "Elle m'a demandé de vous guetter".

### Grimoire d'Aelindra — contenu enrichi
**Décision :** 8 lignes. Aelindra nomme son titre, confirme qu'Aldric savait, pose le choix moral.
**Impact :** Flow : grimoire → await dialogue_fini → 0.4s cooldown → loop choix jusqu'à input.

### Menu principal
**Décision :** menu_principal.tscn + scripts/ui/menu_principal.gd. Boutons Commencer/Quitter. Scène de démarrage changée.
**Impact :** Le jeu démarre sur le menu, pas directement sur Zone 1.

---

## 2026-09-12 — Nettoyage de la documentation et de la configuration

### DECISIONS.md — suppression d'une duplication
**Décision :** Le fichier contenait deux copies concaténées du document (une ancienne version tronquée de 190 lignes, suivie de la version complète). L'ancienne copie est supprimée.
**Raison :** Accident de concaténation lors d'une session précédente. Deux titres, deux sections "À décider" — le fichier devenait illisible et risquait de faire perdre le fil du scope réel.
**Impact :** Un seul document linéaire. Les décisions révisées par un pivot ultérieur sont désormais annotées sur place plutôt que contredites silencieusement.

### Docs de combat — archivées
**Décision :** `docs/characters/kael_combat.md` et `mira_combat.md` déplacés dans `docs/archive/`, avec un bandeau expliquant qu'ils décrivent le pivot RPG abandonné.
**Raison :** Ils décrivaient des mécaniques (Adrénaline, Ouvertures, bombes offensives, stamina) qui n'existent pas dans le jeu. Les laisser dans `docs/characters/` laissait croire qu'ils faisaient partie du design actif.
**Impact :** `docs/` ne contient plus que le design réellement implémenté. Matière conservée pour un futur projet.

### project.godot — clés de configuration invalides
**Décision :** Suppression de `config/run/main_scene` (doublon) et correction de `config/run/max_fps` en `run/max_fps`.
**Raison :** Sous la section `[application]`, Godot 4 attend `run/main_scene` et `run/max_fps`. Le préfixe `config/` créait des clés inconnues, ignorées par le moteur — **le cap à 60 fps n'était donc jamais appliqué**.
**Impact :** Le framerate est réellement limité à 60. Une seule déclaration de scène de démarrage.

### GAME_DESIGN.md — cohérence du scope
**Décision :** Le tableau des zones et la section Zone 2 sont explicitement marqués "vision future". La durée Zone 1 est harmonisée à ~45 min.
**Raison :** Le document annonçait "Zone 1 uniquement, ~45 min" en tête puis listait 5 zones et "Zone 1 : 1h30" plus bas.
**Impact :** Plus d'ambiguïté sur ce qui est à développer.

---

## 2026-09-12 — UI : HUD par joueur et gestionnaire d'interactions

### Bug corrigé — le bouton d'interaction était lu par deux systèmes
**Décision :** Créer un AutoLoad `InteractionManager`, seul endroit du jeu qui lit le bouton "interagir" et décide qui doit répondre.
**Raison :** Chaque PNJ lisait l'input dans son propre `_process`, et le `DialogueManager` lisait le même bouton pour avancer d'une ligne. Les deux s'exécutaient dans la même frame : appuyer sur A faisait avancer le dialogue **puis** le PNJ le relançait depuis la ligne 1. Le texte restait bloqué sur sa première ligne tant que le joueur restait à portée du PNJ.
**Impact :**
- `scripts/globals/interaction_manager.gd` (nouvel AutoLoad, après DialogueManager)
- `pnj.gd` ne lit plus l'input : il s'enregistre auprès du gestionnaire et expose `declencher()` + `obtenir_verbe()`
- `DialogueManager.bloque_interaction()` couvre la frame de fermeture du dialogue, où `_actif` repasse à false avant que les autres systèmes n'aient tourné

### HUD dans chaque moitié d'écran
**Décision :** Le HUD est un `Control` placé **à l'intérieur du SubViewport** de chaque joueur, pas dans un CanvasLayer global.
**Raison :** Chaque jumeau a son propre curseur de moralité et sa propre cible d'interaction. Dans une barre commune, chaque joueur devrait chercher laquelle des deux barres est la sienne, et le prompt deviendrait ambigu quand les deux peuvent interagir.
**Impact :** `scripts/ui/hud_joueur.gd`, instancié deux fois dans `main.tscn` avec `id_joueur` 1 et 2. La boîte de dialogue reste globale — elle est partagée par les deux joueurs.

### Moralité — affichage discret
**Décision :** La barre de moralité reste invisible et n'apparaît que quelques secondes quand la valeur bouge, puis s'efface en fondu.
**Raison :** Ambiance Ghibli — pas de jauge permanente qui surveille le joueur. Il sent son évolution sans avoir un HUD de jeu vidéo sous les yeux.
**Impact :** `GameManager` émet `moralite_changee(id_joueur, valeur)`. Le HUD de chaque joueur ignore le signal de l'autre.

### Tests automatisés
**Décision :** Deux tests headless dans `tools/tests/`, lancés à la main en ligne de commande.
**Raison :** Le bug d'interaction était invisible à la lecture et pénible à reproduire à la main. `test_interaction.gd` a un mode « contrôle négatif » (`-- --bug`) qui reproduit l'ancien comportement et doit échouer — ça prouve que le test teste vraiment quelque chose.
**Impact :** Voir l'en-tête de chaque fichier pour la commande exacte.

---

## 2026-09-12 — Puzzles branchés sur l'UI + nettoyage du code mort

s
### Code mort supprimé
**Décision :** Retrait de la plomberie d'interaction inutilisée de `character_base.gd` (`_peut_interagir`, `entrer_zone_interaction`, `quitter_zone_interaction`, `_verifier_interaction`, signal `interaction_declenchee`) et des `interagir()` vides de Kael et Mira.
**Raison :** `entrer_zone_interaction()` n'était appelé nulle part, donc `_peut_interagir` restait toujours `false` et les `interagir()` ne s'exécutaient jamais. Leurs en-têtes annonçaient « Interagir (A) → Carnet des Anciens », ce qui était faux et trompeur.
**Impact :** Le Carnet des Anciens et le Sac d'Alchimiste restent documentés comme hors scope Zone 1, mais ne laissent plus de fausse piste dans le code.

### Puzzle 3 — suppression d'une double lecture
**Décision :** La logique passe par le signal `lianes_invoquees` de Kael au lieu de relire `joueur1_skill1` dans `_process`.
**Raison :** Le signal était connecté à une fonction vide pendant que `_process` refaisait le travail. Deux chemins pour une seule action.

---

## 2026-09-19 — Habillage du village (décor Zone 1)

### Un fichier séparé pour le décor
**Décision :** Tout le décor visuel vit dans `scripts/zones/decor_village.gd` (`class_name DecorVillage`), instancié par `zone1.gd` juste après la géométrie de base.
**Alternative écartée :** continuer à empiler les `_mur()` / `_maison()` dans `zone1.gd`, qui portait déjà la géométrie, les puzzles et le grimoire.
**Raison :** Le décor est purement cosmétique et va beaucoup bouger pendant le polish. Le sortir permet de le relire, de le retoucher ou de le couper (une ligne dans `_habiller_le_village()`) sans jamais risquer la logique de la zone.
**Impact :**
- La liste des maisons vit maintenant dans `zone1.gd` (`const MAISONS`) : une seule source de vérité, utilisée pour bâtir les murs ET pour poser les toits.
- Contenu : toits en prisme + façades (portes, fenêtres éclairées, colombages), chemins de dalles, terre battue, ~150 arbres, herbe, fleurs, rochers, puits habillé, tonneaux, caisses, bottes de foin, charrette, étal de marché, corde à linge, potager, clôtures, 6 lanternes.

### Le décor n'a (presque) pas de collision
**Décision :** Tout le décor est en `MeshInstance3D` nu. Seuls les troncs d'arbres reçoivent un `StaticBody3D`.
**Raison :** Le plaisir actuel du jeu vient de la liberté de déplacement. Une centaine de petits obstacles invisibles (caisses, fleurs, dalles) transformerait la balade en parcours d'accrochage.

### Emplacements interdits
**Décision :** `_emplacement_libre()` refuse tout objet aléatoire sur la rue principale, le pied de l'Aelith, les maisons, la palissade, le passage de la porte nord et **toute la zone du Puzzle 3** (x de -40 à -8, z de -42 à -14).
**Raison :** Un arbre planté devant la roue à eau ou les lianes cacherait une pièce de puzzle. Le décor ne doit jamais coûter en lisibilité.
**Note :** La graine aléatoire est fixe (`GRAINE = 20260919`) — le village est identique à chaque lancement, donc testable.

### Sol en prairie plutôt qu'en terre
**Décision :** `COULEUR_SOL` passe de beige-sable à vert prairie ; le décor repose des plaques de terre battue là où le village vit (place, devant des maisons).
**Raison :** Un sol sable uniforme donnait un rendu désertique, à l'opposé du ton Ghibli de `ART_DIRECTION.md`. L'inverse (vert partout + usure là où l'on marche) lit tout de suite comme un village habité.

### Sol agrandi + brouillard de distance
**Décision :** Une seule dalle de sol (110 × 105) au lieu de trois, et `fog_enabled` dans l'`Environment` de `main.tscn` (densité 0.0022).
**Raison :** L'ancien sol s'arrêtait à z=-40 : **la stèle du Pacte (z=-44) et la ZoneGrimoire (z=-40) flottaient au-dessus du vide**. La dalle élargie laisse en plus la place à la forêt qui ferme l'horizon, et le brouillard léger adoucit le bord de la carte.

### La vieille maison du nord existe enfin
**Décision :** Une ruine en pierre est bâtie autour de la `ZoneGrimoire` (8, 0, -40).
**Raison :** Le dialogue de fin de zone annonce « quelque chose brille dans la vieille maison au nord » alors qu'il n'y avait rien à cet endroit. Les joueurs cherchaient un bâtiment inexistant.

### Outil de capture
**Décision :** `tools/capture_zone1.tscn` photographie la zone sous plusieurs angles sans lancer le jeu (`godot --path . res://tools/capture_zone1.tscn`). Sorties dans `tools/captures/`, ignoré par git.
**Raison :** Juger un décor demande de le voir. Se déplacer à la manette jusqu'au nord de la carte à chaque retouche est trop lent.

---

## 2026-09-19 — Test : modéliser les bâtiments dans Blender

### Blender scripté, pas Blender à la souris
**Décision (test concluant) :** Les bâtiments sont générés par un script Python exécuté par Blender en ligne de commande — `blender --background --python tools/gen_maison.py` → `assets/models/environnement/maison_a.glb`, `maison_b.glb`, `moulin.glb`.
**Alternative écartée :** modéliser à la main dans l'interface de Blender.
**Raison :** Même pipeline que `gen_aelith.py`, déjà en place. Un paramètre à changer (largeur, teinte du toit, nombre de rangs de bardeaux) = une ligne, et les trois bâtiments se régénèrent en 3 secondes. Le fichier de génération est versionné et relisible ; un `.blend` ne l'est pas.
**Coût mesuré :** 5 200 faces pour une maison, 6 400 pour le moulin — négligeable, même en écran splitté.

### Ce qui fait vraiment la différence
Constat du test, par ordre d'impact :
1. **Les arêtes biseautées.** Un cube parfait n'a aucun liseré de lumière sur ses arêtes, d'où l'aspect « bloc ». 2 cm de biseau suffisent.
2. **La silhouette** — débord de toit, cheminée, auvent, soubassement : des décrochements lisibles de loin.
3. **L'irrégularité** — chaque poutre tournée d'un ou deux degrés au hasard (paramètre `tordu`).
4. **Le toit en rangs de bardeaux** plutôt qu'une pente lisse.
Le nombre de polygones n'est nulle part dans cette liste. On reste en Ghibli stylisé, pas en photoréalisme, qui jurerait avec les personnages et `ART_DIRECTION.md`.

### Deux pièges rencontrés (à ne pas réapprendre)
- **Espace colorimétrique.** Blender attend du **linéaire**, Godot affiche du **sRGB**, et le glTF transporte la valeur telle quelle. Sans conversion, toutes les couleurs ressortent délavées (0.55 linéaire ≈ 0.76 à l'écran). D'où `vers_lineaire()` dans `gen_maison.py`.
- **Cache d'import.** Regénérer un `.glb` ne suffit pas : Godot sert la version en cache dans `.godot/`. Il faut `godot --headless --path . --import` avant de relancer.

### Pas de roue à aubes sur le moulin
**Décision :** Le moulin reçoit une potence de grenier (poutre, poulie, sac), pas une roue.
**Raison :** Il est à (-22, -12), loin du ruisseau, et le Puzzle 3 a déjà sa roue à trente mètres. Deux roues dans le champ brouilleraient la lecture du puzzle.

---

## 2026-09-19 — Les maisons Blender sont en jeu

### Collision et modèle sont séparés
**Décision :** `zone1.gd` pose une **boîte de collision invisible** pour chaque maison ; `DecorVillage` instancie le **modèle .glb** par-dessus. Le joueur se cogne toujours à la boîte, jamais au modèle.
**Alternative écartée :** générer la collision depuis le maillage du .glb (`-col` / trimesh à l'import).
**Raison :** Une collision trimesh sur un modèle à 5 000 faces est coûteuse et imprévisible (on s'accroche dans un avant-toit, dans une marche). Une boîte reste lisible et gratuite. La boîte couvre les **murs seulement** : on passe donc sous le débord de toit, ce qui est le comportement attendu.
**Impact :** `MODELES` (l'emprise des murs de chaque modèle) et `MAISONS` (modèle, position au sol, rotation, échelle) en haut de `zone1.gd`. `emprise()` est la seule source de vérité pour la taille, partagée avec le décor.

### Trois modèles pour sept maisons
**Décision :** `maison_a`, `maison_b`, `moulin`, répétés avec des rotations et des échelles différentes (0.90 à 1.15).
**Raison :** Sept fichiers pour sept maisons, c'est sept fois plus d'assets à regénérer pour le moindre changement de style. La rotation et l'échelle suffisent à casser la répétition, et l'échelle est **uniforme** — une échelle non uniforme déformerait les poutres.
**Exception :** la maison de l'oiseau (22, -6) reste à `rot = 0`. Le perchoir du Puzzle 2 est calé sur son faîtage ; la tourner décalerait le perchoir de la ligne de faîte.

### Le perchoir et l'oiseau ont été remontés
**Décision :** Perchoir à y = 7.25, oiseau à y = 7.78 (contre 6.2 et 5.0 avant).
**Raison :** Le modèle monte à ~7.0 m (murs 4.57 + toit 2.46) contre 6.2 m pour l'ancienne boîte. **L'oiseau était déjà enfoui dans l'ancien toit** à y = 5.0 — le bug préexistait, il est corrigé au passage. `puzzle_oiseau.gd` lit la position de départ dans la scène, il n'y avait donc rien à changer côté code.

---

## 2026-09-19 — Caméra : rotation verticale

### Orbite sur deux axes
**Décision :** `camera_follow.gd` gagne un angle vertical (`_angle_v`), borné entre -29° et +78°. La souris (clic droit) et le stick droit le pilotent, convention **non inversée** : souris vers le haut = on regarde vers le haut.
**Raison :** La caméra ne tournait qu'à l'horizontale. On ne pouvait voir ni la canopée de l'Aelith — l'élément central de la zone — ni le sol.
**Impact :** `distance` et `hauteur` décrivent maintenant la position de DÉPART ; `_ready()` les convertit en rayon d'orbite (10,8 m) et angle initial (34°). Le cadrage au démarrage est identique à l'ancien, au centimètre près.

### Viser plus haut quand le sol bloque
**Décision :** Sous `HAUTEUR_MIN` (0,8 m), la caméra ne descend plus — et ce qu'elle ne peut pas faire en descendant, elle le fait en **visant au-dessus du personnage**.
**Raison :** Une caméra orbitale qui vise toujours le personnage doit passer SOUS lui pour regarder vers le haut. Sur un sol plat, elle se retrouve sous terre. Sans compensation, la borne basse ne servait à rien : le test mesurait 1° de plus que l'horizontale. Avec, on monte à 29° — la canopée remplit l'écran.
**Note :** `HAUTEUR_MIN` suppose un sol plat à y = 0. À revoir le jour où il y a du relief.

### Limite connue — la caméra traverse le feuillage
En visée plongeante près de l'Aelith, la caméra monte à ~11 m et se retrouve **dans** la canopée. Un raycast caméra ne corrigerait rien : le feuillage du GLB n'a pas de collision (seul le tronc en a une, posée par `zone1.gd`). À traiter, si ça gêne en playtest, en bridant l'angle haut à proximité de l'arbre.

### Ressenti — le modèle du pivot
**Décision :** La caméra est accrochée **rigidement** à un point invisible (le pivot) ; c'est le PIVOT qui suit le personnage en douceur, pas la caméra.
**Alternative écartée :** amortir la position de la caméra (`global_position.lerp(vise, 0.08)`), ce qui était fait jusqu'ici.
**Raison :** Amortir la caméra amortit AUSSI sa rotation. Le joueur pousse le stick, l'image suit un dixième de seconde plus tard : c'est la sensation de caméra « molle », accrochée par un élastique. Pire, le déplacement du personnage est calculé sur `get_angle_h()`, l'angle d'ENTRÉE, donc les commandes tournaient instantanément pendant que l'image traînait. Avec le pivot : la rotation répond à l'image près, et la caméra garde son retard agréable quand on marche.

### Trois autres corrections de ressenti
1. **Amortissement indépendant du framerate.** `lerp(x, 0.08)` par frame rendait la caméra deux fois plus vive à 120 fps qu'à 60. Remplacé par `1 - exp(-vitesse * delta)`. `lissage` (0.08) devient `vitesse_suivi` (12,0 par seconde).
2. **Le pivot vise la tête** (`HAUTEUR_REGARD` = 1 m au-dessus de l'origine du personnage), pas les pieds. Viser les pieds tasse l'horizon en haut de l'écran.
3. **Zone morte + réponse au carré sur le stick.** En linéaire, au quart du stick on tourne déjà au quart de la vitesse max : impossible d'ajuster finement. Au carré, le début de course est lent et précis, la vitesse maximale est inchangée.

### Test
`tools/tests/test_camera.gd`, 14 vérifications. Il contrôle la **direction du regard** et le **ressenti**, pas seulement la position : que la rotation soit rigide (aucun retard après un quart de tour), que le suivi donne le même résultat à 60 et à 120 fps, et que la courbe du stick soit bien progressive. Ces trois propriétés sont invisibles à la lecture et faciles à casser par accident.

### Reste à voir
`character_base.gd` amortit l'orientation du personnage avec `lerp_angle(..., 0.15)`, qui a le même défaut de dépendance au framerate. Pas touché : ça change le ressenti du personnage, pas de la caméra.

---

## 2026-09-19 — Modélisation : arbres, Aelith, personnages

### Une boîte à outils Blender partagée
**Décision :** `tools/blender_commun.py` porte la palette, la conversion sRGB→linéaire, les primitives (`boite`, `boule`, `cylindre`, `branche`) et l'export. Les scripts de génération n'ont plus que la forme à décrire.
**Raison :** `gen_maison.py` avait déjà sa propre copie de `vers_lineaire()` et de l'export. Trois scripts de plus, c'était trois copies à maintenir.
**Note :** `gen_maison.py` n'a PAS été migré vers ce module — il marche, et le migrer pour le plaisir risquerait de casser trois assets validés. À faire à la prochaine retouche des maisons.

### Les arbres
**Décision :** 4 essences + 1 buisson (`tools/gen_arbres.py`), affichés en **MultiMesh**.
**Raison forme :** Ce qui fait qu'un arbre ressemble à un arbre, dans l'ordre : l'empattement des racines, la ramification (du feuillage AU BOUT des branches), la canopée en grappes de tailles et teintes variées, l'asymétrie. Pas le nombre de polygones — chaque arbre fait 1 000 à 1 900 faces.
**Raison MultiMesh :** ~190 arbres × 2 vues (écran splitté) = 380 ordres de dessin pour la seule forêt. Un `MultiMeshInstance3D` par essence : 5 ordres de dessin. Le prix : tous les arbres d'une essence partagent le même maillage, la variété vient de la rotation et de l'échelle.
**Piège rencontré :** un MultiMesh n'utilise QUE le maillage, pas le noeud qui le porte — or Godot range le maillage d'un .glb sous un noeud portant la conversion d'axes Blender (Z haut) → Godot (Y haut). Sans recomposer cette transformation, **tous les arbres sont couchés au sol**. Voir `_maillage_du_modele()`.

### L'Aelith — le village est DANS le tronc
**Décision :** L'Aelith n'est plus un arbre au centre du village : c'est un tronc creux de 56 m de rayon et 62 m de haut **qui contient toute la zone jouable**. Sylvara s'est installée dans la cavité ; la paroi est son rempart naturel, avec deux ouvertures — l'entrée sud et la sortie nord, derrière la Porte Double du Puzzle 1.
**Alternative écartée :** un arbre géant classique au centre de la place. Un tronc majestueux fait au moins 18 m de diamètre : il écrasait le puits, Vaenmor et la moitié des chemins.
**Raison :** C'est l'idée du joueur, et elle tient debout : elle explique pourquoi le village n'a jamais été attaqué, elle donne une échelle qu'aucun arbre posé au sol ne peut donner, et elle rend la géométrie du niveau narrative (les deux seules ouvertures sont l'entrée et la sortie).
**Conséquences assumées :**
- Il n'y a **pas de tronc au centre** : le centre est la place. Le petit saule qui y pousse (`nimbus_willow`, déjà là) devient un **rejet de l'Aelith** — l'arbre-enfant au coeur de l'arbre-parent.
- Un **oculus** : la canopée s'écarte au-dessus du centre. Sans lui le village serait dans le noir, et Gwanur est Ghibli, pas souterrain.
- Le soleil est passé de 45° à 68° d'élévation et l'ambiante de 0.5 à 1.05. À 45°, le rempart de 62 m jetait une ombre de 62 m et plongeait la moitié du village dans le noir.
- Le brouillard passe de 0.0022 à 0.0008 : on regarde maintenant à 150 m, plus à 40.
- Le sol passe à 260 × 260 pour porter toute la canopée.
- La forêt du décor reste à moins de 48 m du centre de l'anneau — au-delà, les arbres poussaient dans le mur.
- ⚠ **Le LORE n'a pas été mis à jour.** `docs/LORE.md` décrit encore un village autour de l'arbre. À reprendre.

### Les personnages
**Décision :** Kael et Mira sont modélisés (`tools/gen_personnages.py`), ~1 200 faces chacun, **sans squelette ni animation**.
**Raison :** À 9 m — la distance de la caméra — ce qui identifie un personnage est sa silhouette, sa couleur dominante et son équipement qui déborde de la silhouette. Pas son visage. D'où : Kael élancé, tunique verte, oreilles pointues, brassards de Sève lumineux, corne dans le dos ; Mira plus ramassée, plastron de cuir auburn, grappin de cuivre à l'avant-bras, lanterne allumée à la hanche, sac d'alchimiste.
**Limite connue :** ils glissent sans marcher. Le rig et les animations sont un chantier à part entière, pas un ajustement.
**Orientation :** le modèle regarde +Z, ce qu'attend `character_base.gd` (`rotation.y = atan2(direction.x, direction.z)`).

### Reste en capsules : les PNJ
Les neuf villageois (`pnj.gd`) sont encore des capsules colorées, ce qui se voit maintenant que les héros sont modélisés. Réutiliser le corps de `gen_personnages.py` avec d'autres teintes est la suite logique — la difficulté est de pouvoir changer la couleur de la tunique par PNJ sans un .glb par villageois.

### Incident
`tools/gen_aelith.py` (l'ancien Aelith « v4 », dont le .glb n'était pas branché dans la scène) a été écrasé par erreur, puis restauré depuis git. Le nouveau script vit à côté, sous `gen_aelith_v2.py`.

---

## 2026-10-30 — Outillage et organisation de la finition

### On reste sur Godot
**Contexte :** question posée — vaut-il le coup de passer sur Unreal Engine ?
**Décision :** Non. Gwanur reste sur Godot 4.6.
**Alternatives écartées :** migrer vers Unreal Engine 5.
**Raison :** La Zone 1 est jouable de bout en bout ; migrer, c'est tout réécrire (personnages, puzzles, PNJ, trois AutoLoads, split-screen, HUD, géométrie procédurale) pour revenir au même point, et réapprendre un moteur plus lourd (Blueprints/C++, Actors, GameMode, local players). Les forces d'Unreal (Nanite, Lumen, photoréalisme) ne servent pas un style Ghibli stylisé, et Lumen coûte cher en split-screen (deux rendus par image). L'objectif est de **finir et publier**. Unreal reste une option pour un PROCHAIN projet démarré de zéro.

### MCP Godot
**Décision :** Le serveur MCP `@coding-solo/godot-mcp` est enregistré dans la config locale de Claude Code (scope projet local, `GODOT_PATH` vers `Godot_v4.6.2-stable_win64_console.exe`).
**Alternatives écartées :** MCP Unreal (moteur abandonné ci-dessus) ; `youssof20/godot-mcp` (plugin d'éditeur à installer dans le projet) ; `matula/godot-mcp-server`.
**Raison :** le plus utilisé (~4,6k étoiles, MIT), aucun plugin à ajouter au projet ; il permet à Claude de lancer le jeu et de lire les erreurs sans copier-coller.

### Une équipe d'agents pour finir la Zone 1
**Décision :** Six rôles définis dans `.claude/agents/` (graphiste, scénariste, développeur, sound designer, testeur, reviewer) + règles communes dans `.claude/equipe.md`. Chaque agent travaille dans son propre worktree git avec un **périmètre de fichiers exclusif**, puis l'orchestrateur fusionne sur `feat/finition-zone1`.
**Alternatives écartées :** tout faire en séquence dans une seule session (trop long) ; agents en parallèle dans le même dossier (imports Godot concurrents dans `.godot/`, éditions croisées).
**Raison :** les chantiers restants (son, visuel, textes, flux de jeu, tests) sont indépendants s'ils ne touchent pas les mêmes fichiers.
**Règles qui en découlent :**
- Les agents n'écrivent pas dans ce fichier : ils rendent leurs décisions dans leur rapport et l'orchestrateur les consolide ici (sinon conflit de fusion garanti).
- `scripts/ui/textes_narration.gd` est un **contrat** : le scénariste en écrit le contenu, le développeur ne fait que le lire (constantes `INTRO`, `FIN_SECRET`, `FIN_PARTAGE`, `FIN_COMMUNE`, `CREDITS`).
- `.claude/` étant ignoré par git, les définitions d'agents restent locales à cette machine.

---

## 2026-10-30 — Finition Zone 1 : décisions de l'équipe

> Consolidé par l'orchestrateur à partir des rapports des six agents.

### Narration (scénariste)
- **La stèle ne nomme plus Aelindra**, seulement « la Tisserande » et « Aldric, émissaire d'Arathos ». C'est le grimoire qui révèle que la mère était la Tisserande. *Écarté :* garder les deux prénoms (plus de mystère) ou ne nommer personne (plus de révélation dans un jeu réduit à la Zone 1). Le lien Aelric = Ael(indra) + (Ald)ric est laissé au joueur attentif.
- **Une Tisserande renonce à son nom** : l'Histoire ne retient que le titre, d'où le fait qu'Aelindra ait pu garder son prénom au village. *Écarté :* un faux nom (il aurait fallu réécrire tous les dialogues).
- **Le jeu tient en une journée** : la mère part dans la nuit, les jumeaux trouvent le lit vide au matin. Les dialogues qui parlaient de « trois jours » ou de « mois » sont harmonisés.
- **Les jumeaux habitent Sylvara** depuis le Pacte, et le village se tait par affection (Eldwen ne demande plus « vous venez de loin ? »).
- **Vocabulaire** : le saule central s'appelle « le Rejet », l'oculus « le Trou de Ciel ».
- **Les indices nomment le jumeau et l'objet** (« Kael… ta corne », « Mira… ta lanterne »), parce que le public cible inclut un non-gamer. La poésie reste dans la phrase.

### Flux de jeu (développeur)
- **Deux manettes** : Kael = manette 0 + clavier ZQSD/E/A/R, Mira = manette 1 + flèches/Entrée/Maj droit/Ctrl droit. Caméras sur des actions `joueurN_camera_*`, si bien que `project.godot` est le seul endroit qui dit quelle manette appartient à qui. La croix était décalée d'un cran (boutons 12-15 au lieu de 11-14) : corrigé. `ui_accept` inclut le bouton A pour les menus.
- **Fin de zone par signal** : `GameManager.zone1_finie` est écouté par `main.gd`, qui orchestre intro → jeu → fin → crédits → menu. *Écarté :* que `zone1` appelle `main` directement.
- **Narration sans pause de l'arbre** : pendant l'intro et la fin, `InteractionManager.suspendre()` et `controles_actifs = false`. `get_tree().paused` reste réservé au menu pause.
- **Intro seulement si `main` est la scène racine**, pour ne pas casser les tests qui instancient `main.tscn` dans leur propre scène.
- **Remise à zéro au clic sur « Commencer »** (`GameManager.reinitialiser()`, qui vide aussi l'InteractionManager), un seul point d'entrée par partie.
- **Fin de zone vérifiée après chaque puzzle**, dans `_verifier_fin_de_zone()` : les puzzles se résolvent dans n'importe quel ordre. Avant, le grimoire n'apparaissait que si le Puzzle 3 était le dernier (blocage).
- **Le DialogueManager a une file d'attente** (FIFO, sans doublon) : `afficher()` ne remplace plus le dialogue en cours. *Écarté :* des priorités (trop complexe) ou refuser le message (perdu).
- **Le choix du grimoire passe par `DialogueManager.proposer_choix()`** : les deux options sont affichées ensemble et les appuis ignorés pendant 0,8 s. `zone1.gd` ne lit plus le bouton (règle d'or respectée).
- **Tout message soumis à un minuteur passe par l'état coop**, jamais par un dialogue : un dialogue ouvert bloque les interactions (le premier appui de Mira au verrou était perdu).
- **Appui simultané** : fusionné seulement si les deux joueurs visent la même cible.
- **Corne** : portée de 12 m mesurée à l'horizontale (l'oiseau est à 7,8 m de haut ; avec 8 m en 3D, il ne restait que 1,7 m² de sol utilisable). Retour au joueur s'il est trop loin.
- **Prérequis Lira** activé (`EXIGER_LIRA = true` en tête de `puzzle_oiseau.gd`), avec un message qui oriente vers elle. Une ligne à changer pour le désactiver.
- **Prompts** : (E) ou (Entrée) au clavier, (A) à la manette, selon le dernier périphérique touché par CE joueur (`scripts/ui/touches_joueur.gd`).
- **Démarche procédurale** sur le noeud `Modele` (jamais sur le CharacterBody3D, sinon la collision bouge). L'orientation du personnage ne dépend plus du framerate (`VITESSE_ROTATION = 10` ≈ l'ancien `lerp 0.15` à 60 fps).
- **Piège Godot rencontré** : on ne peut pas changer `monitoring` d'une Area3D pendant son propre `body_entered` (le grimoire se relançait à chaque entrée). Il faut passer par `set_deferred`.

### Visuel (graphiste)
- **Heure dorée par la couleur, pas par l'angle du soleil** : soleil doré à 64°, tonemapping ACES, ambiante chaude moins forte, brouillard chaud, SSAO et glow légers. *Écarté :* soleil bas à 20-30°, avec lequel le rempart de 62 m plonge toute la cavité dans l'ombre.
- **PNJ : 4 silhouettes** (ancien, villageois, villageoise, enfant) et la tunique recolorée par PNJ via le matériau nommé `tunique_pnj`. *Écarté :* un .glb par PNJ. La silhouette est choisie d'après le nom du noeud (surchargeable par `@export silhouette`).
- **Props des puzzles en enfants du noeud animé** ; la boîte d'origine est cachée, pas supprimée. Si un .glb manque, le jeu retombe sur les boîtes.
- **Géométrie de niveau corrigée** (bugs du testeur) :
  - La palissade nord est maintenant **est-ouest** et va jusqu'à la paroi. Avant, elle était nord-sud et on contournait les puzzles.
  - Une cour fermée entre la grille et la porte ; la grille en est la seule entrée.
  - Les ouvertures sud, est et ouest du rempart sont fermées côté extérieur (on pouvait faire le tour par dehors).
  - Le ruisseau barre le passage grâce à une collision invisible, retirée sous le pont quand celui-ci est déployé. *Écarté :* creuser le terrain.
  - Brennan sort de la collision du moulin (il était inaccessible, donc la zone ne pouvait pas se finir) ; Lira sort du mur de sa maison.
  - La transform de Zone1 dans `main.tscn` revient à l'identité (Kael apparaissait perché sur le cylindre du saule).
- **Bug corrigé** : `blender_commun.py` exportait les .glb vers le dépôt principal en chemin dur. Il est maintenant calculé depuis l'emplacement du script.
- **`capture_zone1.gd` reprend l'éclairage de `main.tscn`** : sa copie avait dérivé, et on jugeait une lumière qui n'était pas celle du jeu.

### Son (sound designer)
- **Tout l'audio est synthétisé** par `tools/gen_audio.py`, exécuté avec le Python de Blender (qui a numpy) : 3 musiques (ré lydien), 2 ambiances, 22 bruitages, 21,5 Mo. *Écarté :* banques de sons (licences), synthèse en GDScript.
- **Boucles sans couture par repliement** de la queue sur le début ; les bruits d'ambiance sont périodiques par construction.
- **Bruitages en 2D, pas en 3D** : avec deux caméras dans deux SubViewports, un son 3D n'a qu'un seul point d'écoute. Léger panoramique (Kael à gauche, Mira à droite) par les bus `SFX_Gauche` et `SFX_Droite` ; le volume du ruisseau dépend de la proximité, calculée à la main.
- **Un seul fichier pour l'audio** (`AudioManager`) : il trouve seul les noeuds (`node_added`) et lit leur état quand il n'y a pas de signal. Aucun script de jeu n'appelle l'audio, sauf `jouer_fin()`.
- **Boucle réglée en code** (`loop_mode`), puisque les .import ne sont pas versionnés.

### Tests (testeur)
- **`test_parcours_complet` joue toute la Zone 1 dans la vraie `main.tscn`.** Trois sortes de lignes : `OK`, `ECHEC` (parcours cassé), `BUG` (défaut connu, non compté ; `-- --strict` les compte). Les placements des héros passent par une requête physique sur leur capsule, jamais par une téléportation aveugle : c'est ce qui a révélé que Brennan était inaccessible.
- Les contrôles comparent aux constantes du code (`TextesNarration`, `INDICE_GRIMOIRE`) ou à des mots-clés, jamais à des phrases recopiées, pour que le scénariste puisse réécrire sans casser le test.

### Corrections de la review (développeur, passe 3)
- **La grille du Puzzle 2 ne retombe jamais sur quelqu'un.** Après les 12 s, elle ne se referme que si personne n'est « derrière » : dans la cour, au nord de la palissade, ou dans une bande de 0,6 m sous la grille. Le test est une fonction de position (`zone1.derriere_la_grille()`) calculée sur les constantes de zone1. *Écarté :* une Area3D créée en code (bornes recopiées, détection seulement à l'entrée). *Raison :* la grille enfermait Kael dans la cour, hors de portée de l'oiseau, ce qui bloquait la partie. Test : `tools/tests/test_cour_oiseau`.
- **Signaux explicites plutôt que lecture d'état** : `puzzle_oiseau` émet `oiseau_appele` et `grille_changee(ouverte)`, `puzzle_roue_eau` émet `pont_s_avance` et `pont_deploye`. Zone1 et l'AudioManager s'y branchent au lieu d'attendre des durées recopiées à la main. Le ruisseau sonore lit les constantes de zone1.
- **L'AudioManager liste ce dont il dépend** (`DEPENDANCES_PUZZLES`) et prévient par un `push_warning` si un puzzle ou un signal a disparu. Avant, renommer un fichier coupait le son sans rien dire.
- **Rien ne tourne pendant la pause**, sauf la musique : pas les bruits de pas, ni les minuteries de gameplay (`create_timer(..., false)`).
- **La fin vide les dialogues** (`DialogueManager.masquer()`) et la stèle se tait une fois le choix fait.

### Cible visuelle : Breath of the Wild
**Contexte :** après un test rapide, l'utilisateur juge le jeu « loin d'un Zelda-like », et les héros glissent sans bouger les jambes.
**Décision :** la cible visuelle devient **Zelda Breath of the Wild** : cel-shading doux, herbe dense au vent, ciel peint. Les **packs d'assets gratuits CC0** (Quaternius, Kenney…) sont autorisés en plus des modèles générés par script. Chaque pack est tracé dans `assets/models/vegetation/LICENCES.md`.
**Alternatives écartées :** Wind Waker (toon franc, plus « dessin animé ») ; Link's Awakening (effet jouet, moins Ghibli) ; rester 100 % généré par script.
**Raison :** BotW est le plus proche de l'ambiance Ghibli d'ART_DIRECTION.md. Le gain vient surtout du **rendu** (shader toon, feuillage, herbe, ciel), pas du nombre de polygones. Pour la végétation, des packs CC0 font mieux que nos scripts, pour bien moins d'effort.
**Héros :** squelette et animations (idle, marche, course) générés par script Blender, à la place de la seule démarche procédurale.

### Rendu BotW (graphiste rendu)
- **Le soleil éclairait par en dessous.** L'axe -Z de la `DirectionalLight3D` de `main.tscn` pointait vers le haut : le sol, les toits et l'herbe ne recevaient que la lumière ambiante, d'où une bonne part de l'aspect terne. Le soleil est remis à 62° d'élévation.
- **Conversion automatique des matériaux** : `scripts/rendu/stylisation.gd` convertit au chargement chaque `StandardMaterial3D` en matériau toon (2 paliers doux, ombres teintées froides, liseré lumineux). Il gère les .glb, les boîtes construites en code, les MultiMesh et les meshes skinnés, avec un seul matériau toon par matériau d'origine. Les feuillages (`feuill`, `leaf`, `foliage`, `aiguille`) reçoivent du vent et des normales sphériques. *Écarté :* retoucher chaque modèle, ou un post-traitement plein écran. Interrupteur pour comparer : `const ACTIVE` ou `-- --sans-toon`.
- **Herbe en parcelles MultiMesh de 8 m** (`scripts/zones/herbe.gd`) : environ 9 touffes/m², vent en vagues, brins qui s'écartent sous les héros, aucune herbe sur les chemins, les maisons ni les pièces de puzzle. *Écarté :* un seul MultiMesh (aucun culling possible) ou des particules GPU.
- **Ciel peint** avec nuages qui dérivent ; **rayons de lumière par l'oculus** en cylindres additifs. *Écarté :* le brouillard volumétrique, payé deux fois en split-screen.
- **Pas de contours** : BotW n'en a presque pas, ses silhouettes se lisent par le liseré et les ombres teintées. Des contours tireraient vers Wind Waker.
- **Coût mesuré** (RX 6600, 1080p, deux vues) : de 150 à 200 fps, environ 3 ms GPU par vue. Le toon seul coûte 0,1 à 0,2 ms par vue. Outil : `tools/mesure_fps.tscn`.

### Végétation CC0 (graphiste végétation)
- **Pack Quaternius « Ultimate Nature »** (CC0 1.0, vérifié sur la page officielle et dans le `License.txt` du pack) : 29 modèles, tracés dans `assets/models/vegetation/LICENCES.md`. *Écarté :* le Stylized Nature MegaKit (sur itch.io, non téléchargeable automatiquement).
- **Recoloration par script Blender versionné** (`tools/recolor_cc0.py`) : couleurs unies de la palette, et les matériaux de feuillage s'appellent `feuillage*`. Les .fbx sources ne sont pas versionnés (`tools/sources_cc0/` est dans le .gitignore).
- **Composition** : 42 bosquets d'une seule famille d'arbres, avec des clairières entre eux. Petits éléments en cases de 20 m, parce que `visibility_range_end` ne sert à rien sur un MultiMesh qui couvre tout le village. Les ordres de dessin baissent d'environ 40 %.
- **Protection automatique des puzzles** : les PNJ et les pièces de puzzle sont relevés dans la scène, et rien ne pousse près d'eux. Des couloirs de vue restent dégagés vers l'oiseau et vers la roue.

### Animation (animateur)
- **Squelette par script** (`tools/animer_personnages.py`) : 15 os, chaque pièce rigide rattachée à un seul os avec un poids de 1.0. *Écarté :* des poids automatiques (coudes « en caoutchouc »).
- **Animations calculées en Python** : idle, marche, course, interagir, skill1, skill2. Pour la marche et la course, on place le pied puis on en déduit la jambe, donc les pieds ne patinent pas. *Écarté :* des animations Mixamo ou CC0, qu'il faudrait recibler sur notre squelette.
- **Contrat de foulée** : 1,2 m (marche) et 3,0 m (course) par cycle de 1 s, partagé par le .py et `character_base.gd` ; la vitesse de lecture vaut vitesse / foulée.
- **AnimationTree construit en code**. Les gestes ne jouent que sur le haut du corps, donc les jambes continuent de marcher. Accélération 30 m/s² et freinage 36 m/s², sans changer la vitesse max (5 m/s), donc les timings des puzzles restent les mêmes.
- **PNJ** : même squelette, idle animée, ils tournent doucement le corps vers le joueur le plus proche (6 m, 70° au plus).

### La fleur sans nom, derrière le pont
**Contexte :** depuis que le ruisseau est un vrai obstacle, le pont du Puzzle 3 menait à une bande de terrain fermée et vide. Et l'intro annonce « Sur l'oreiller, une seule fleur. Ni Kael ni Mira n'en connaissent le nom. »
**Décision :** la même fleur pousse dans le bief (`scripts/zones/fleur_bief.gd`, modèle `tools/gen_fleur.py`). C'est la preuve qu'Aelindra est passée par le pont la nuit de son départ. Un seul `PointInteraction`, ouvert aux deux joueurs, donne une réaction différente à Kael et à Mira, puis une ligne commune quand les deux l'ont vue. **Optionnelle** : elle n'est jamais un prérequis. Si on l'a trouvée, `TextesNarration.FIN_FLEUR` s'ajoute à l'écran de fin.
**Le nom n'est jamais dit dans le jeu.** Dans le LORE, c'est le même mot que le vrai nom de la Tisserande, réservé à la Zone 5. *Écarté :* lui donner un nom elfique ou populaire. *Raison :* on tient la promesse de l'intro, et on ne grille pas une révélation future.
**Lisibilité :** fleur agrandie (hampe d'environ 1 m), pétales « blanc de lune » légèrement émissifs, et une file de pétales tombés depuis le pont, comme des pas. *Écarté :* une lumière forte. Les matériaux ne contiennent pas « feuill », sinon la stylisation les traiterait comme du feuillage d'arbre.
**Contrat :** `textes_narration.gd` gagne `FIN_FLEUR`. Les autres textes de la fleur vivent dans `fleur_bief.gd`, comme ceux des puzzles.

### Finitions visuelles et sonores
- **Chemins pavés** : chaque chemin est un seul ruban plat dessiné par `shaders/paves.gdshader` (pavage de Voronoi déformé, pierres dorées variées, jointures où l'on voit le sol), au lieu de 76 dalles rectangulaires. L'ombre de la pierre est teintée chaud : les pavés ne virent plus au mauve sous la canopée. *Écarté :* des pierres en MultiMesh (centaines d'instances et d'ombres, payées deux fois). Coût : environ +0,3 ms GPU sur la vue qui les montre. Les tirages aléatoires sont identiques, donc le décor ne bouge pas.
- **Le Rejet (saule)** ramené dans la palette par un réglage par texture dans `stylisation.gd` (`REGLAGES_TEXTURE` : désaturation, reflets dorés). *Écarté :* retoucher les PNG ou réexporter le .glb de 11 Mo. Ça reste réversible et versionné en code. `tools/recolor_willow.py` est obsolète.
- **Feuillage de l'Aelith sans facettes** : normales sphériques par grappe, calculées à la génération dans Blender (`marquer_grappe()` dans `blender_commun.py`). Coût nul à l'exécution. *Écarté :* le calcul dans le shader (un seul centre sur 110 m).
- **Pas calés sur les appuis** : l'AudioManager lit la phase de l'AnimationTree (`parameters/allure/current_position`) et joue un pas à chaque passage de 0 et 0,5. Résultat : un pas tous les 0,6 m en marche et 1,5 m en course, plus fort en course. *Écarté :* des pistes « method » dans les animations (doubles déclenchements pendant le mélange).
- **Gros rochers solides** : cylindre de collision légèrement plus étroit que la pierre. Mieux vaut un rocher qu'on frôle qu'un mur invisible.

### Export Windows
**Décision :** `export_presets.cfg` est versionné (chemins relatifs uniquement) et produit `build/windows/Gwanur.exe`, un exécutable unique de 136 Mo dans lequel le jeu est embarqué (`embed_pck`). `tools/` et `docs/` sont exclus du jeu exporté. `build/` est ignoré par git.
**Templates :** les templates officiels Godot 4.6.2 ont été téléchargés depuis la page des releases GitHub de Godot, vérifiés par SHA-512 contre `SHA512-SUMS.txt`, et seuls les Windows x86_64 ont été installés dans `%APPDATA%/Godot/export_templates/4.6.2.stable/`.
**Licences :** Godot est sous licence MIT, et son texte doit accompagner le jeu. `tools/licences_export.gd` génère `build/windows/LICENCES.txt` (Godot, ses composants tiers, nos packs CC0) à partir de ce que le moteur fournit lui-même. Il est à relancer après chaque export.
**Vérification d'un export :** les templates officiels refusent qu'on leur impose une scène en ligne de commande, même en debug. Pour tester la scène de jeu embarquée, on lance le binaire de l'éditeur depuis un dossier hors du projet : `godot --headless --main-pack build/windows/Gwanur.exe res://scenes/main.tscn --quit-after 900`. Seuls les fichiers réellement exportés sont alors utilisés.
**Procédure complète :**
```
godot --headless --path . --export-release "Windows Desktop" build/windows/Gwanur.exe
godot --headless --path . --script res://tools/licences_export.gd
```

### Organisation — ce qu'on a appris
- **Les worktrees d'agents partent parfois d'un vieux commit** (ici c89c7d0, le pivot RPG) au lieu de la branche courante. Chaque agent doit vérifier sa base en premier.
- **Les agents ne lancent ni Godot ni Blender pendant que l'utilisateur joue** sur la même machine : les fenêtres le dérangent.

---

## À décider — Zone 1

- [x] Les lettres d'Aldric — lettre 1 livrée par Vaenmor
- [x] Dialogues de Vaenmor, Lira, Brennan
- [x] Le contenu exact du grimoire d'Aelindra
- [x] La musique — thème Zone 1, menu, fin (piano, harpe, flûte, cordes, ré lydien)
- [x] Intro (Acte 0), écran de fin, crédits, menu pause
- [ ] Nom à mettre dans les crédits (marqueur `[NOM DU DÉVELOPPEUR]`)
- [x] Ce qu'il y a de l'autre côté du pont du Puzzle 3 → la fleur sans nom (voir ci-dessous)
- [x] Export Windows → `build/windows/Gwanur.exe` + `LICENCES.txt`
- [x] Le menu principal
- [x] UI — HUD moralité + indicateur d'interaction (par joueur, dans son SubViewport)
- [x] UI — retour visuel sur la progression du Puzzle 1 (message d'état coop)
- [ ] Détails visuels de l'Aelith (le modèle GLB est là, pas d'interaction propre)
