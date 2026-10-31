# Végétation — provenance et licences

Tout ce dossier vient de packs d'assets **CC0** (domaine public), autorisés
depuis le 2026-10-30 (voir `docs/DECISIONS.md`, « Cible visuelle : Breath of
the Wild »). CC0 n'exige aucune attribution ; on trace quand même chaque pack
ici, pour savoir d'où vient chaque fichier et le créditer par politesse.

Les modèles ne sont **pas** les fichiers d'origine : ils ont été recolorés à la
palette du jeu, recentrés sur le pied du tronc et mis à l'échelle par
`tools/recolor_cc0.py` (Blender). Seuls les `.glb` produits sont versionnés.

## quaternius/ — « Ultimate Nature Pack »

| | |
|---|---|
| Auteur | Quaternius (https://quaternius.com — https://www.patreon.com/quaternius) |
| Page officielle | https://quaternius.com/packs/ultimatenature.html |
| Téléchargement | lien « Download » de la page officielle → dossier Google Drive `1-Kl0L_Jg8awbh0S5T-z3zxh4mVlnxTpa` (format FBX) |
| Licence | **CC0 1.0 Universal** — https://creativecommons.org/publicdomain/zero/1.0/ |
| Vérification | 1) la page officielle affiche « CC0 » dans son encart Licence ; 2) le `License.txt` livré dans le pack dit « License: CC0 1.0 Universal (CC0 1.0) Public Domain Dedication » |
| Téléchargé le | 2026-10-30 |

Correspondance fichier du pack → fichier du jeu :

| Pack (.fbx) | Jeu (.glb) | Rôle |
|---|---|---|
| CommonTree_1, CommonTree_2 | feuillu_large_1, feuillu_large_2 | grands chênes/hêtres, canopée large |
| CommonTree_3 | feuillu_haut | feuillu élancé |
| CommonTree_4 | feuillu_rond | feuillu moyen, rond |
| CommonTree_5 | feuillu_jeune | jeune arbre |
| CommonTree_Autumn_2 | feuillu_dore | l'arbre doré (rappel de l'Aelith) |
| BirchTree_1, BirchTree_5 | bouleau_1, bouleau_2 | bouleaux |
| PineTree_2, _3, _4 | pin_1, pin_2, pin_3 | conifères |
| Willow_2 | saule | saule (bords du ruisseau) |
| Bush_1, Bush_2, BushBerries_1 | buisson_1, buisson_2, buisson_baies | buissons |
| Plant_1, Plant_3, Plant_4 | fougere_basse, fougere, fougere_large | fougères |
| Flowers, Plant_5 | fleurs_touffe, fleurs_hautes | fleurs |
| Rock_1, Rock_4 | rocher_1, rocher_2 | rochers nus |
| Rock_Moss_2, _3, _5, _6, _7 | rocher_moussu_1 … _5 | rochers moussus |
| TreeStump_Moss | souche | souche moussue |
| WoodLog_Moss | tronc_couche | tronc couché moussu |

## Pour regénérer

Les `.fbx` sources ne sont pas dans git (`tools/sources_cc0/` est ignoré).
Pour refaire les `.glb` : télécharger le pack depuis la page officielle,
copier les `.fbx` listés ci-dessus et le `License.txt` dans
`tools/sources_cc0/quaternius_ultimate_nature/`, puis :

    blender --background --factory-startup --python tools/recolor_cc0.py
    godot --headless --path . --import
