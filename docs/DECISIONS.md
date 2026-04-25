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
