# tools/recolor_willow.py
#
# Importe nimbus_willow_2_tree.glb, change la couleur des feuilles
# vers la palette Aelith de Gwanur (or ambré, feuilles "presque dorées"),
# et ré-exporte en aelith_final.glb.
#
# Usage : blender --background --python tools/recolor_willow.py

import bpy
import os

DIR        = r"C:\Users\PC\Documents\repo_git\Gwanur\assets\models\environnement"
SOURCE     = os.path.join(DIR, "nimbus_willow_2_tree.glb")
OUTPUT     = os.path.join(DIR, "aelith_final.glb")

# ── Nettoyer ──────────────────────────────────────────────────────────────────

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# ── Importer le GLB ───────────────────────────────────────────────────────────

bpy.ops.import_scene.gltf(filepath=SOURCE)
print("\n── Matériaux trouvés ──────────────────────────────────────────")
for mat in bpy.data.materials:
    if mat.use_nodes:
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        col  = bsdf.inputs["Base Color"].default_value[:3] if bsdf else "?"
    else:
        col = "no nodes"
    print(f"  [{mat.name}]  base_color={col}")
print("───────────────────────────────────────────────────────────────\n")

# ── Identifier les matériaux "feuilles" ──────────────────────────────────────
#
# On cherche les mots-clés typiques des feuilles dans les noms de matériaux.
# Si rien ne matche on affiche un avertissement.

# Les feuilles du nimbus_willow sont des plans nommés "Plane_XXX"
MOTS_FEUILLES = ["leaf", "leave", "foliage", "frond", "canopy",
                 "feuille", "green", "branch_top", "plane_"]

mats_feuilles = [
    mat for mat in bpy.data.materials
    if any(kw in mat.name.lower() for kw in MOTS_FEUILLES)
]

print(f"Matériaux feuilles ciblés : {[m.name for m in mats_feuilles]}\n")

# ── Palette Gwanur — Aelith ───────────────────────────────────────────────────
#
# Lore : "feuilles presque dorées"
# Or ambré chaud, légèrement désaturé pour rester crédible.

OR_AMBRÉ    = (0.88, 0.68, 0.07, 1.0)   # Feuilles éclairées
OR_PROFOND  = (0.55, 0.38, 0.03, 1.0)   # Sous-feuillage / ombre

def recolorer_mat_feuilles(mat, couleur_base):
    if not mat.use_nodes:
        return

    # Chercher un nœud Principled BSDF par type (pas juste par nom)
    bsdf = None
    for node in mat.node_tree.nodes:
        if node.type == 'BSDF_PRINCIPLED':
            bsdf = node
            break

    if bsdf:
        bsdf.inputs["Base Color"].default_value = couleur_base
        bsdf.inputs["Roughness"].default_value  = 0.65
        try:
            bsdf.inputs["Emission Color"].default_value    = (1.0, 0.82, 0.25, 1.0)
            bsdf.inputs["Emission Strength"].default_value = 0.12
        except KeyError:
            pass
        print(f"  ✓ {mat.name} → or ambré (via BSDF_PRINCIPLED)")
        return

    # Fallback : chercher un nœud RGB ou Diffuse et forcer la couleur
    for node in mat.node_tree.nodes:
        if node.type in ('BSDF_DIFFUSE', 'EMISSION', 'RGB'):
            if "Color" in node.inputs:
                node.inputs["Color"].default_value = couleur_base
                print(f"  ✓ {mat.name} → or ambré (via {node.type})")
                return

    print(f"  ⚠ {mat.name} → nœud non trouvé, reconstruction du matériau")
    # Reconstruction complète avec Principled BSDF
    mat.node_tree.nodes.clear()
    out  = mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    bsdf = mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs["Base Color"].default_value = couleur_base
    bsdf.inputs["Roughness"].default_value  = 0.65
    mat.node_tree.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    print(f"  ✓ {mat.name} → matériau reconstruit, or ambré")

for i, mat in enumerate(mats_feuilles):
    # Alterner légèrement entre or vif et or profond pour du volume
    couleur = OR_AMBRÉ if i % 3 != 2 else OR_PROFOND
    recolorer_mat_feuilles(mat, couleur)

# ── Export ────────────────────────────────────────────────────────────────────

bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(
    filepath      = OUTPUT,
    use_selection = True,
    export_format = 'GLB',
    export_apply  = False,   # Pas d'apply — on veut garder les transforms originaux
)

print(f"\n✅  Exporté → {OUTPUT}\n")
