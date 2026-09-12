# Gwanur

Jeu de puzzles coopératif local, développé avec Godot 4.6.

**Deux joueurs obligatoires.** Zéro combat. Une expérience courte et complète
d'environ 45 minutes.

## Histoire

Deux jumeaux demi-elfes adolescents, **Kael** et **Mira**, doivent collaborer pour
traverser le Village des Lisières, aux portes des Terres Grises. Leur mère a
disparu ; le village sait des choses qu'il ne dit pas.

| Personnage | Héritage | Équipement |
|---|---|---|
| Kael | Magie elfique (nature) | Brassards de Sève, Corne d'Appel, Carnet |
| Mira | Robustesse humaine | Grappin de Cuivre, Lanterne à Mémoire, Sac d'Alchimiste |

Aucun puzzle ne se résout seul — tous exigent la coordination des deux joueurs.

## Style visuel

3D semi-réaliste style anime (Genshin Impact / Tales of Arise) avec une ambiance
Studio Ghibli : tons chauds, lumière douce, mélancolie tranquille.

## Contrôles

Écran partagé vertical. **Deux manettes** (device 0 et device 1) :
stick gauche pour se déplacer, A pour interagir, X et Y pour les deux skills.

Le clavier ZQSD + E / A / R reste disponible comme fallback de développement
pour le joueur 1.

## Moteur

- Godot 4.6 (version Standard, pas .NET)
- Renderer : Forward Plus
- 1920×1080, 60 fps
- Plateforme cible : PC (Windows, Linux, macOS)

## Structure du projet

```
assets/       Art, audio, polices
  models/     Modèles 3D (environnement, personnages)
  audio/      Musique et effets sonores
  fonts/      Polices
scenes/       Scènes Godot (.tscn)
  menu_principal.tscn  Scène de démarrage
  main.tscn            Scène de jeu (split-screen)
  test_mecanique.tscn  Banc de test (sol plat, sans puzzles)
  characters/          Kael, Mira
  zones/               Zone 1
  ui/                  Interface (à venir)
scripts/      Scripts GDScript (.gd)
  characters/ Kael, Mira et leur base commune
  puzzles/    Les 3 puzzles de la Zone 1
  npcs/       PNJ et dialogues
  zones/      Construction et orchestration de la Zone 1
  globals/    GameManager, DialogueManager (AutoLoads)
  camera/     Caméra qui suit un personnage
  ui/         Menu principal
tools/        Scripts Python hors-jeu (génération et retouche d'assets)
docs/         Notes de design et documentation
  archive/    Designs abandonnés — pas des références
```

## Démarrage (développement)

1. Installer [Godot 4.6](https://godotengine.org/download) (version Standard, pas .NET)
2. Ouvrir Godot → cliquer **Importer** → naviguer vers ce dossier → sélectionner `project.godot`
3. Cliquer **Ouvrir et éditer** — Godot importe les assets et ouvre l'éditeur
4. Appuyer sur **F5** pour lancer le jeu (démarre sur le menu principal)

Pour tester le mouvement sans charger la Zone 1, ouvrir `scenes/test_mecanique.tscn`
et appuyer sur **F6**.

## Statut

Zone 1 jouable de bout en bout. Reste le polish : UI/HUD, son, et remplacement
de la géométrie procédurale par les assets finaux.

Voir `CLAUDE.md` pour le briefing complet et `docs/DECISIONS.md` pour l'historique
des décisions.
