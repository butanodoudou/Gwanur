# tools/gen_aelith.py — v4 (Gwanur / Ghibli)
#
# Aelith — Arbre Monde du Village des Lisières.
# Adapté depuis un prompt FFT-isométrique vers l'univers Gwanur :
#   - Tronc tordu et massif, évasé à la base
#   - Racines qui s'étalent et tombent comme une falaise
#   - Branches larges et noueuses (sphères de jointure)
#   - Feuillage dense en clusters dorés (pas vert — lore Gwanur)
#   - Toon shading 3 bandes : ombre / mi-teinte / lumière
#   - Backlight doré sacré derrière le tronc
#
# Différences clés vs FFT : vue 3D exploration (pas isométrique),
# palette Gwanur (écorce blanche, or ambré), proportions Ghibli.
#
# Usage : blender --background --python tools/gen_aelith.py
# Sortie : assets/models/environnement/aelith.glb

import bpy
import bmesh
import math
import random
import os
from mathutils import Vector, Matrix

OUTPUT_DIR  = r"C:\Users\PC\Documents\repo_git\Gwanur\assets\models\environnement"
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "aelith.glb")

os.makedirs(OUTPUT_DIR, exist_ok=True)
random.seed(7)

# ── Nettoyer ──────────────────────────────────────────────────────────────────

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
for d in [bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.curves]:
    for b in list(d):
        d.remove(b)

liste_objets = []

# ── Palette Gwanur — Aelith ───────────────────────────────────────────────────
#
# Lore : "écorces blanches, feuilles presque dorées"
# Adapté depuis : tronc brun FFT → blanc crème ancien Gwanur
#                 feuilles vertes FFT → or ambré Gwanur

C_ECORCE_LUM   = (0.95, 0.93, 0.90, 1.0)   # Blanc ivoire — zones éclairées
C_ECORCE_MI    = (0.70, 0.65, 0.58, 1.0)   # Beige gris — mi-teinte
C_ECORCE_OBR   = (0.38, 0.32, 0.24, 1.0)   # Brun chaud — ombre profonde
C_FEUILLES_LUM = (0.90, 0.72, 0.08, 1.0)   # Or vif — lumière directe
C_FEUILLES_MI  = (0.65, 0.50, 0.04, 1.0)   # Or terne — mi-teinte
C_FEUILLES_OBR = (0.30, 0.20, 0.02, 1.0)   # Brun doré — ombre sous canopée
C_BACKLIGHT    = (1.00, 0.85, 0.40)         # Halo doré sacré

# ── Matériaux toon — 3 bandes dures (Constant) ───────────────────────────────

def creer_mat_toon(nom, col_ombre, col_mi, col_lumiere, emission=0.0):
    """
    Toon shader 3 bandes via Diffuse → ShaderToRGB → ColorRamp CONSTANT.
    Exporte en GLB avec l'albedo le plus proche (col_lumiere comme base PBR).
    Le cel-shading complet sera finalisé côté Godot via un shader.
    """
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    n = mat.node_tree.nodes
    lk = mat.node_tree.links
    n.clear()

    out   = n.new('ShaderNodeOutputMaterial')
    diff  = n.new('ShaderNodeBsdfDiffuse')
    s2rgb = n.new('ShaderNodeShaderToRGB')
    ramp  = n.new('ShaderNodeValToRGB')
    bsdf  = n.new('ShaderNodeBsdfPrincipled')

    # Couleur de base pour l'export GLB (PBR)
    bsdf.inputs['Base Color'].default_value = col_lumiere
    bsdf.inputs['Roughness'].default_value  = 0.85
    bsdf.inputs['Specular IOR Level'].default_value = 0.05

    # ColorRamp 3 bandes : ombre → mi → lumière
    diff.inputs['Color'].default_value = col_lumiere
    ramp.color_ramp.interpolation = 'CONSTANT'
    ramp.color_ramp.elements[0].position = 0.00
    ramp.color_ramp.elements[0].color    = col_ombre
    mid = ramp.color_ramp.elements.new(0.38)
    mid.color = col_mi
    ramp.color_ramp.elements[2].position = 0.68
    ramp.color_ramp.elements[2].color    = col_lumiere

    # Pour le rendu Blender : chemin toon
    lk.new(diff.outputs['BSDF'],   s2rgb.inputs['Shader'])
    lk.new(s2rgb.outputs['Color'], ramp.inputs['Fac'])

    # Pour l'export GLB : chemin PBR (Principled)
    lk.new(bsdf.outputs['BSDF'], out.inputs['Surface'])

    # Émission légère sur feuilles (lueur sacrée)
    if emission > 0:
        em  = n.new('ShaderNodeEmission')
        mix = n.new('ShaderNodeMixShader')
        em.inputs['Color'].default_value    = col_lumiere
        em.inputs['Strength'].default_value = emission
        mix.inputs['Fac'].default_value     = 0.12
        lk.new(bsdf.outputs['BSDF'], mix.inputs[1])
        lk.new(em.outputs['Emission'],   mix.inputs[2])
        lk.new(mix.outputs['Shader'],    out.inputs['Surface'])

    return mat

mat_ecorce   = creer_mat_toon("Ecorce_Aelith",
                               C_ECORCE_OBR, C_ECORCE_MI, C_ECORCE_LUM)
mat_feuilles = creer_mat_toon("Feuilles_Aelith",
                               C_FEUILLES_OBR, C_FEUILLES_MI, C_FEUILLES_LUM,
                               emission=0.25)
mat_sous     = creer_mat_toon("SousFeuilles_Aelith",
                               C_FEUILLES_OBR, C_FEUILLES_OBR, C_FEUILLES_MI)

# ── Helpers ───────────────────────────────────────────────────────────────────

def appliquer_mat(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mat)

def lisser(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.shade_smooth()

def rot_vers_dir(direction):
    d = Vector(direction).normalized()
    z = Vector((0, 0, 1))
    a = z.angle(d)
    ax = z.cross(d)
    if ax.length < 0.001:
        return (0.0, 0.0, 0.0)
    r = Matrix.Rotation(a, 4, ax.normalized()).to_euler()
    return (r.x, r.y, r.z)

# ── Tronc tordu ───────────────────────────────────────────────────────────────
#
# Cylinder 20 côtés → twist manual en bmesh (rotation progressive autour de Z)
# + évasement exponentiel à la base + bosses irrégulières pour texture visuelle.

HAUTEUR_TRONC = 13.0
RAYON_BASE    =  2.4

bpy.ops.mesh.primitive_cylinder_add(
    vertices=20, radius=RAYON_BASE, depth=HAUTEUR_TRONC,
    location=(0, 0, HAUTEUR_TRONC / 2)
)
tronc = bpy.context.active_object
tronc.name = "Tronc"

bpy.ops.object.mode_set(mode='EDIT')
bm = bmesh.from_edit_mesh(tronc.data)
for v in bm.verts:
    # Hauteur normalisée 0 (bas) → 1 (haut)
    t = (v.co.z) / HAUTEUR_TRONC  # v.co.z est déjà centré, décaler
    t_abs = (v.co.z + HAUTEUR_TRONC / 2) / HAUTEUR_TRONC
    t_abs = max(0.0, min(1.0, t_abs))

    # 1) Twist : 35° de torsion totale, progressif
    twist = t_abs * math.radians(35)
    x_new = v.co.x * math.cos(twist) - v.co.y * math.sin(twist)
    y_new = v.co.x * math.sin(twist) + v.co.y * math.cos(twist)
    v.co.x, v.co.y = x_new, y_new

    # 2) Évasement à la base (exponentiel inverse)
    if t_abs < 0.5:
        flare = 1.0 + (1.0 - t_abs * 2) ** 2.2 * 0.65
        v.co.x *= flare
        v.co.y *= flare

    # 3) Effilement vers le haut
    if t_abs > 0.15:
        taper = max(0.18, 1.0 - (t_abs - 0.15) ** 1.6 * 0.88)
        v.co.x *= taper
        v.co.y *= taper

    # 4) Bosses organiques (irrégularité de surface)
    angle_v = math.atan2(v.co.y, v.co.x)
    bruit   = (math.sin(angle_v * 3 + t_abs * 7) * 0.06
             + math.sin(angle_v * 5 - t_abs * 11) * 0.03)
    dist    = math.sqrt(v.co.x**2 + v.co.y**2)
    if dist > 0.01:
        v.co.x += (v.co.x / dist) * bruit
        v.co.y += (v.co.y / dist) * bruit

bmesh.update_edit_mesh(tronc.data)
bpy.ops.object.mode_set(mode='OBJECT')
appliquer_mat(tronc, mat_ecorce)
lisser(tronc)
liste_objets.append(tronc)

# ── Racines — s'étalent et tombent comme une falaise ─────────────────────────
#
# 9 racines : certaines plates (au sol), certaines inclinées vers le bas
# pour simuler l'effet "falaise" du prompt.

racines_config = [
    # angle, dist_base, longueur, rayon, incli_vers_bas, hauteur_départ
    (0.0,        2.0,  5.5, 0.65,  0.20, -0.5),
    (0.70,       1.8,  4.8, 0.55,  0.35, -0.3),
    (1.40,       2.2,  6.0, 0.70,  0.15, -0.6),
    (2.09,       1.9,  5.2, 0.58,  0.50, -0.2),   # tombe en falaise
    (2.79,       2.1,  5.8, 0.62,  0.12, -0.4),
    (3.49,       1.8,  4.5, 0.52,  0.45, -0.1),   # tombe en falaise
    (4.19,       2.3,  6.2, 0.68,  0.18, -0.5),
    (4.89,       1.7,  4.3, 0.50,  0.38, -0.2),
    (5.59,       2.0,  5.0, 0.60,  0.25, -0.4),
]

for i, (ang, dist, lng, ray, incli, h_dep) in enumerate(racines_config):
    dx = math.cos(ang)
    dy = math.sin(ang)
    dz = -incli  # vers le bas pour l'effet falaise

    start  = Vector((dx * dist * 0.3, dy * dist * 0.3, h_dep))
    d_norm = Vector((dx, dy, dz)).normalized()
    mid    = start + d_norm * lng * 0.5
    rot    = rot_vers_dir((dx, dy, dz))

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=8, radius=ray, depth=lng,
        location=mid, rotation=rot
    )
    racine = bpy.context.active_object
    racine.name = f"Racine_{i}"

    # Évasement à la jonction avec le tronc
    bpy.ops.object.mode_set(mode='EDIT')
    bm2 = bmesh.from_edit_mesh(racine.data)
    centre_local = Vector((0, 0, 0))
    for v in bm2.verts:
        # Extrémité proche du tronc = épaissir
        dist_bout = v.co.z + lng / 2  # 0 = bout tronc, lng = extrémité
        if dist_bout < lng * 0.3:
            factor = 1.0 + (1.0 - dist_bout / (lng * 0.3)) * 0.55
            v.co.x *= factor
            v.co.y *= factor
    bmesh.update_edit_mesh(racine.data)
    bpy.ops.object.mode_set(mode='OBJECT')

    appliquer_mat(racine, mat_ecorce)
    lisser(racine)
    liste_objets.append(racine)

# ── Branches noueuses — 3 niveaux ────────────────────────────────────────────

def ajouter_branche_noueuse(start, direction, longueur, rayon, nom):
    """Branche avec sphère de jointure (nœud) à la base."""
    d   = Vector(direction).normalized()
    mid = Vector(start) + d * longueur * 0.5
    rot = rot_vers_dir(direction)

    # Corps de la branche
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=9, radius=rayon, depth=longueur,
        location=mid, rotation=rot
    )
    branche = bpy.context.active_object
    branche.name = nom
    appliquer_mat(branche, mat_ecorce)
    lisser(branche)
    liste_objets.append(branche)

    # Nœud à la jonction (sphère légèrement plus grosse)
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=10, ring_count=7,
        radius=rayon * 1.45,
        location=start
    )
    noeud = bpy.context.active_object
    noeud.name = f"{nom}_noeud"
    appliquer_mat(noeud, mat_ecorce)
    lisser(noeud)
    liste_objets.append(noeud)

    return Vector(start) + d * longueur   # extrémité

# Niveau 1 — 7 grands bras (étalés, légèrement courbés visuellement)
extremites_n1 = []
for i in range(7):
    ang  = (i / 7) * 2 * math.pi + random.uniform(-0.15, 0.15)
    h    = random.uniform(7.5, 10.5)
    dx   = math.cos(ang)
    dy   = math.sin(ang)
    dz   = random.uniform(0.20, 0.42)
    lng  = random.uniform(6.5, 9.0)
    ray  = random.uniform(0.42, 0.58)
    end  = ajouter_branche_noueuse((0,0,h), (dx,dy,dz), lng, ray, f"BN1_{i}")
    extremites_n1.append((end, ang))

# Niveau 2 — 3 sub-branches par N1
extremites_n2 = []
for j, (pos_n1, ang_parent) in enumerate(extremites_n1):
    for k in range(3):
        spread = random.uniform(-0.8, 0.8)
        ang2   = ang_parent + spread
        dz2    = random.uniform(0.30, 0.65)
        lng2   = random.uniform(3.5, 5.5)
        ray2   = random.uniform(0.18, 0.28)
        end2   = ajouter_branche_noueuse(
            pos_n1, (math.cos(ang2), math.sin(ang2), dz2),
            lng2, ray2, f"BN2_{j}_{k}"
        )
        extremites_n2.append(end2)

# Niveau 3 — petites branches terminales
for m, pos_n2 in enumerate(extremites_n2):
    for n in range(2):
        ang3  = random.uniform(0, 2 * math.pi)
        dz3   = random.uniform(0.50, 0.90)
        lng3  = random.uniform(1.6, 2.8)
        ray3  = random.uniform(0.06, 0.11)
        ajouter_branche_noueuse(
            pos_n2, (math.cos(ang3), math.sin(ang3), dz3),
            lng3, ray3, f"BN3_{m}_{n}"
        )

# ── Feuillage dense — 3 couches ───────────────────────────────────────────────
#
# Couche 1 : grands clusters (r=3-4.5) — structure visible de loin
# Couche 2 : clusters moyens (r=1.8-2.8) — remplissage
# Couche 3 : petits clusters sombres (r=1.0-1.6) — ombre sous canopée

CENTRE_Z   = 15.5
RXY        = 9.8
RZ         = 4.5

def generer_points_canopee(n, r_xz_min, r_xz_max, z_min_abs=10.5):
    pts = []
    tries = 0
    while len(pts) < n and tries < 2000:
        tries += 1
        theta = random.uniform(0, 2 * math.pi)
        phi   = math.acos(random.uniform(-0.6, 1.0))
        r     = random.uniform(r_xz_min, r_xz_max) ** 0.6
        x = r * RXY * math.sin(phi) * math.cos(theta)
        y = r * RXY * math.sin(phi) * math.sin(theta)
        z = CENTRE_Z + r * RZ * math.cos(phi)
        if z < z_min_abs and math.sqrt(x*x + y*y) < 2.5:
            continue
        pts.append((x, y, z))
    return pts

def placer_clusters(points, rayon_min, rayon_max, materiau, suffixe):
    for i, (cx, cy, cz) in enumerate(points):
        r     = random.uniform(rayon_min, rayon_max)
        ez    = random.uniform(0.60, 0.85)
        ex    = random.uniform(0.88, 1.14)
        ey    = random.uniform(0.88, 1.14)
        rot_z = random.uniform(0, 2 * math.pi)
        bpy.ops.mesh.primitive_uv_sphere_add(
            segments=10, ring_count=7,
            radius=r, location=(cx, cy, cz),
            rotation=(0, 0, rot_z)
        )
        cl = bpy.context.active_object
        cl.name   = f"Feuilles_{suffixe}_{i}"
        cl.scale  = (ex, ey, ez)
        appliquer_mat(cl, materiau)
        lisser(cl)
        liste_objets.append(cl)

# Couche 1 — grands clusters lumineux
pts_grands = generer_points_canopee(22, 0.55, 1.00, z_min_abs=12.0)
# Ajouter aux extrémités des branches N2
for p in extremites_n2[:12]:
    pts_grands.append((p.x + random.uniform(-0.5,0.5),
                       p.y + random.uniform(-0.5,0.5),
                       p.z + random.uniform(0.5, 2.0)))
placer_clusters(pts_grands, 2.8, 4.5, mat_feuilles, "grand")

# Couche 2 — clusters moyens, remplissage
pts_moyens = generer_points_canopee(35, 0.20, 0.95, z_min_abs=11.0)
placer_clusters(pts_moyens, 1.8, 2.8, mat_feuilles, "moyen")

# Couche 3 — petits clusters sombres (sous la canopée)
pts_sombres = generer_points_canopee(20, 0.10, 0.75, z_min_abs=10.0)
pts_sombres = [(x, y, z - 1.5) for x, y, z in pts_sombres]  # légèrement plus bas
placer_clusters(pts_sombres, 1.0, 1.7, mat_sous, "sombre")

# ── Backlight doré sacré ──────────────────────────────────────────────────────
#
# Point light placé derrière le tronc (offset négatif Y) et en hauteur.
# Simule la lueur sacrée de l'Aelith dans la scène Godot.

bpy.ops.object.light_add(type='POINT', location=(0, -4.5, 10))
backlight = bpy.context.active_object
backlight.name = "Backlight_Aelith"
backlight.data.color  = C_BACKLIGHT
backlight.data.energy = 800
backlight.data.shadow_soft_size = 3.0
# Note : la lumière n'est pas exportée en GLB standard —
# à recréer dans Godot avec un OmniLight3D aux mêmes paramètres.

# ── Export GLB ────────────────────────────────────────────────────────────────

bpy.ops.object.select_all(action='DESELECT')
for obj in liste_objets:
    obj.select_set(True)

bpy.ops.export_scene.gltf(
    filepath      = OUTPUT_FILE,
    use_selection = True,
    export_format = 'GLB',
    export_apply  = True,
)

nb_feuilles = sum(1 for o in liste_objets if "Feuilles" in o.name)
nb_branches = sum(1 for o in liste_objets if "BN" in o.name or "noeud" in o.name)
print(f"\n✅  Aelith v4 exporté → {OUTPUT_FILE}")
print(f"    Clusters feuilles : {nb_feuilles}")
print(f"    Éléments branches : {nb_branches}")
print(f"    Total objets      : {len(liste_objets)}\n")
