# 🎨 Gwanur — Direction Artistique

## Vision Globale

Style **semi-réaliste anime** en 3D, inspiré de Genshin Impact et Tales of Arise pour les personnages, et de Studio Ghibli pour les environnements et l'ambiance générale. Tons chauds dominants — roux, dorés, terre.

---

## Palette de Couleurs Générale

```
Tons chauds dominants :
├── Auburn        #8B3A2A
├── Doré miel     #D4A843
├── Terre chaude  #8B6347
├── Rouille       #B5451B
└── Beige doré    #E8C99A

Tons froids d'accent :
├── Vert mousse    #4A7C59
├── Gris brume     #8E9BAE
└── Bleu crépuscule #2C4A7C
```

---

## Personnages

### 🌿 Kael

**Palette :** Tons terre, vert naturel, doré
- Peau : Dorée chaude
- Cheveux : Dégradé auburn → doré miel (style anime, mèches légèrement ébouriffées)
- Yeux : Ambrés, grands, expressifs
- Tenue : Brun terre, vert feuille, cuir naturel

**Prompt Meshy / générateur 3D :**
```
half-elf teenage boy, 16 years old, slim athletic build,
semi-realistic anime style, Genshin Impact proportions,
head to body ratio 1:7, lean build, NOT chibi, NOT cartoon,
mature adolescent face, warm golden skin,
large expressive amber eyes,
auburn to golden gradient hair, messy anime style,
pointed ears slightly visible through hair,
worn earthy brown medieval tunic with open collar,
leaf-engraved leather bracers, dark trousers, forest boots,
leather journal on belt, calm dreamy expression,
warm earth and gold tones, 3D game character, game ready, T-pose,
style similar to Tales of Arise or Genshin Impact
```

---

### 🔥 Mira

**Palette :** Rouille, cuivre, laiton
- Peau : Beige chaud teinté doré
- Cheveux : Auburn foncé attaché, mèches rebelles
- Yeux : Ambrés perçants, regard intense
- Tenue : Rouille, cuivre, laiton — veste militaire médiévale

**Prompt Meshy / générateur 3D :**
```
half-elf teenage girl, 16 years old, lean athletic build,
semi-realistic anime style, Genshin Impact proportions,
head to body ratio 1:7, NOT chibi, NOT cartoon,
mature adolescent face, sharp intense features,
small scar on left cheek, light warm beige skin,
sharp amber eyes intense gaze,
dark auburn hair tied back loosely with wild strands escaping,
slightly pointed ears visible,
rust-red fitted medieval jacket with brass buckles and rolled sleeves,
dark fitted trousers, tall worn leather boots,
copper grappling hook attached to belt,
determined fierce expression, confident pose,
warm rust and copper tones, 3D game character, game ready, T-pose,
style similar to Tales of Arise or Genshin Impact
```

---

## Environnements — Par Zone

### Zone 1 — Village des Lisières
- **Ambiance :** Chaud, accueillant, soleil de fin d'après-midi
- **Palette :** Bois chaud, pierre dorée, jardins verts
- **Référence :** Village de Princesse Mononoké, début de Nausicaä

### Zone 2 — Forêt Entrelacée
- **Ambiance :** Mystérieux, lumineux, vivant
- **Palette :** Verts profonds, rayons de lumière dorés, bioluminescence légère
- **Référence :** Forêt de Mon Voisin Totoro, forêt de Mononoké

### Zone 3 — Ruines de l'Entre-Deux
- **Ambiance :** Mélancolique, abandonné, beau dans la décrépitude
- **Palette :** Pierre grise, mousse verte, touches de rouille
- **Référence :** Laputa, château dans le ciel — les ruines envahies de nature

### Zone 4 — Lac des Reflets
- **Ambiance :** Onirique, doux, légèrement troublant
- **Palette :** Bleus et violets doux, reflets dorés sur l'eau, brume légère
- **Référence :** Le voyage de Chihiro — séquences sur l'eau

### Zone 5 — Cœur des Terres Grises
- **Ambiance :** Sacré, intemporel, entre deux mondes
- **Palette :** Blanc lumineux, dorés, verts émeraude, lumière diffuse
- **Référence :** La fin du Voyage de Chihiro, le Château Ambulant

---

## Style des Personnages — Références

| Référence | Ce qu'on en prend |
|---|---|
| Genshin Impact | Proportions anime semi-réalistes, dégradés de cheveux |
| Tales of Arise | Expressions faciales, tenues médiévales détaillées |
| Studio Ghibli | Ambiance, douceur des mouvements, relation avec la nature |
| Zelda Breath of the Wild | Exploration, lumière naturelle |

---

## Pipeline Artistique

```
Meshy AI
└─ Génération des modèles 3D de base (Kael & Mira)
   └─ Export .GLB

VRoid Studio
└─ Affinement du style anime
└─ Customisation des cheveux et dégradés
   └─ Export .VRM

Blender
└─ Ajustement des proportions
└─ Détails (cicatrice Mira, brassards Kael)
└─ Textures et matériaux
   └─ Export .GLB / .FBX

Mixamo
└─ Animations de base (marche, idle, interactions)
   └─ Export vers Godot

Godot 4
└─ Intégration finale
└─ Shaders style anime (cel shading léger)
```

---

## Pipeline Décor — Environnements

### Structure : murs, sols, bâtiments

Approche **kit de modules** — des blocs réutilisables assemblés dans l'éditeur Godot comme des Lego.

**Sources :**
- **Kenney.nl** — [Medieval Builder Pack](https://kenney.nl/assets/medieval-builder) (CC0, gratuit). Mur droit, coin, sol, porte, toit — parfait pour démarrer Zone 1 en une après-midi.
- **Meshy AI** — pour les props uniques et narratifs (grimoire, roue d'eau, perchoir, etc.) qui n'existent pas dans les kits génériques.

**Workflow :**
1. Importer les `.GLB` dans `assets/models/environnement/`
2. Placer dans la scène via l'éditeur Godot (pas en code)
3. Désactiver la géométrie procédurale de `zone1.gd` (les `_bloc()` calls)
4. Les scripts de puzzles et `Area3D` de collision **ne changent pas**

### Ambiance : végétation, lumière, détails

Ce qui crée l'effet Ghibli :

| Élément | Technique Godot |
|---|---|
| Lumière soleil chaud | `DirectionalLight3D` avec `light_color` doré, `shadow_enabled` |
| Intérieurs | `OmniLight3D` placés manuellement |
| Végétation dense | `MultiMeshInstance3D` — milliers de brins d'herbe sans impact perfs |
| Ciel et brume | `WorldEnvironment` — `ProceduralSkyMaterial` + `fog_enabled` |
| Profondeur | Ambient occlusion dans `Environment` + `glow` léger |

### Transition prototype → production

```
Prototype (actuel)
└─ zone1.gd génère les boîtes colorées en code
   └─ Collision = BoxShape3D (permanent)
   └─ Visuel = BoxMesh + StandardMaterial3D (temporaire)

Production (plus tard)
└─ zone1.tscn dans l'éditeur : modules Kenney + props Meshy
   └─ Collision inchangée (scripts de puzzles ne bougent pas)
   └─ Visuel remplacé par les vrais modèles .GLB
```

---

## UI & Interface

- **Style :** Minimal, organique — pas de métal froid ou de néon
- **Fonts :** Serif légèrement manuscrit pour le lore, sans-serif doux pour l'UI
- **HUD :** Très discret, s'efface pendant l'exploration
- **Inventaire :** Style carnet de voyage, textures papier
- **Split-screen :** Séparateur vertical avec motif végétal fin
