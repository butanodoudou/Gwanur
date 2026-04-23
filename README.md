# Gwanur

Jeu d'exploration et puzzles coopératif local, développé avec Godot 4.

## Histoire

Deux jumeaux demi-elfes adolescents, **Kael** et **Mira**, doivent collaborer pour
traverser un monde de fantasy médiévale heroïque. Chaque joueur contrôle un jumeau
via un écran partagé vertical (split-screen).

| Personnage | Capacité | Joueur |
|---|---|---|
| Kael | Magie de la nature — invoque des plantes, appelle des animaux | Joueur 1 (clavier) |
| Mira | Instinct humain — mécanique, grappin | Joueur 2 (manette) |

Pas de combat — tous les défis nécessitent la coopération des deux joueurs.

## Style visuel

Inspiré de Studio Ghibli / anime. Décors peints, personnages expressifs,
palettes de couleurs douces.

## Contrôles

- **Joueur 1 (Kael) :** Clavier + souris
- **Joueur 2 (Mira) :** Manette (Xbox / DualSense)

## Moteur

- Godot 4.3+
- Renderer : Forward Plus
- Plateforme cible : PC (Windows, Linux, macOS)

## Structure du projet

```
assets/       Art, audio, polices
  audio/      Musique et effets sonores
  sprites/    Personnages, environnements, UI
  fonts/      Polices
  tilesets/   Tuiles pour les niveaux
scenes/       Scènes Godot (.tscn)
  main.tscn   Point d'entrée du jeu
  levels/     Niveaux
  characters/ Scènes des personnages
  ui/         Interface utilisateur
scripts/      Scripts GDScript (.gd)
  characters/ Scripts de Kael et Mira
  managers/   Gestionnaires (GameManager, AudioManager...)
  puzzles/    Logique des puzzles
  utils/      Utilitaires
shaders/      Shaders visuels (.gdshader)
docs/         Notes de design et documentation
```

## Démarrage (développement)

1. Installer [Godot 4.3](https://godotengine.org/download) ou plus récent (version Standard, pas .NET)
2. Ouvrir Godot → cliquer **Importer** → naviguer vers ce dossier → sélectionner `project.godot`
3. Cliquer **Ouvrir et éditer** — Godot importe les assets et ouvre l'éditeur
4. Appuyer sur **F5** pour lancer le jeu

## Statut

Phase d'initialisation / scaffolding.
