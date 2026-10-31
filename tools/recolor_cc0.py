# tools/recolor_cc0.py — La végétation CC0, remise à la palette de Sylvara
#
# D'OÙ VIENNENT LES MODÈLES
#   Pack « Ultimate Nature Pack » de Quaternius, licence CC0 (domaine public).
#   Les .fbx d'origine que l'on utilise sont copiés, tels quels, dans
#   tools/sources_cc0/quaternius_ultimate_nature/ (avec leur License.txt).
#   Le dossier porte un fichier `.gdignore` : Godot ne les importe pas, ils ne
#   servent qu'à ce script. Il n'est PAS versionné (.gitignore) : seuls les
#   .glb produits le sont. Pour le reconstituer, voir la liste et le lien de
#   téléchargement dans assets/models/vegetation/LICENCES.md.
#
# CE QUE FAIT LE SCRIPT, POUR CHAQUE MODÈLE
#   1. Importe le .fbx.
#   2. REMPLACE chaque matériau par un matériau simple à la palette de Gwanur
#      (une couleur unie, pas de texture, pas de PBR) — le shader toon du
#      décor reprend cette couleur. Les matériaux de feuillage ont un nom qui
#      contient « feuill » : c'est le contrat avec le shader, qui leur donne un
#      traitement à part (translucidité, vent…). Ne pas les renommer.
#   3. Pose le pied du tronc sur l'origine (pour que la collision cylindre de
#      decor_village.gd tombe pile dans le tronc) et met le modèle à sa
#      hauteur cible, en mètres.
#   4. Exporte un .glb à un seul objet dans assets/models/vegetation/quaternius/
#
#   Les couleurs des packs sont des verts froids et des gris bleutés ; la
#   direction artistique (docs/ART_DIRECTION.md) veut des verts mousse chauds,
#   des troncs bruns chauds et de la pierre dorée. D'où la recoloration ici,
#   une fois pour toutes, plutôt que dans Godot à chaque chargement.
#
# Usage :
#   blender --background --factory-startup --python tools/recolor_cc0.py
# Puis : godot --headless --path . --import

import bpy
import os
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import vers_lineaire, DOSSIER_ASSETS

DOSSIER_SOURCES = os.path.join(
	os.path.dirname(os.path.abspath(__file__)), "sources_cc0", "quaternius_ultimate_nature")
SOUS_DOSSIER = os.path.join("vegetation", "quaternius")


# ── Palette (sRGB, comme le reste du projet) ──────────────────────────────────
# Clé = nom du NOUVEAU matériau. Les feuillages contiennent tous « feuill ».

PALETTE = {
	"ecorce":            (0.40, 0.27, 0.18),   # brun chaud
	"ecorce_claire":     (0.55, 0.38, 0.24),   # coeur de la souche
	"ecorce_bouleau":    (0.86, 0.81, 0.71),   # blanc chaud, pas gris
	"ecorce_tache":      (0.30, 0.24, 0.19),   # les marques du bouleau
	"feuillage":         (0.47, 0.63, 0.31),   # vert mousse ensoleillé
	"feuillage_sombre":  (0.29, 0.47, 0.29),   # le dessous des grappes
	"feuillage_pin":     (0.27, 0.45, 0.33),   # conifère : plus bleu, plus sombre
	"feuillage_pin_sombre": (0.18, 0.34, 0.27),
	"feuillage_saule":   (0.55, 0.66, 0.35),   # saule : plus jaune
	"feuillage_dore":    (0.86, 0.64, 0.27),   # l'arbre doré — rappel de l'Aelith
	"feuillage_dore_clair": (0.93, 0.76, 0.38),
	"feuillage_buisson": (0.40, 0.57, 0.29),
	"feuillage_fougere": (0.38, 0.56, 0.30),
	"feuillage_fougere_sombre": (0.26, 0.43, 0.26),
	"feuillage_sec":     (0.62, 0.50, 0.30),   # Plant_2 : feuilles sèches
	"tige":              (0.36, 0.52, 0.27),   # tiges des fleurs (pas « feuill »)
	"fleur_jaune":       (0.95, 0.80, 0.33),   # doré miel
	"fleur_bleue":       (0.62, 0.68, 0.93),   # bleu crépuscule adouci
	"fleur_rose":        (0.92, 0.55, 0.60),
	"baie":              (0.78, 0.22, 0.18),
	"pierre":            (0.68, 0.61, 0.50),   # pierre dorée
	"mousse":            (0.42, 0.55, 0.28),
	"champignon":        (0.72, 0.33, 0.20),
	"champignon_pied":   (0.90, 0.82, 0.68),
}

# Correspondance matériau du pack → matériau Gwanur, par « famille » de modèle.
# Ce qui n'est pas listé tombe dans DEFAUT.
DEFAUT = {
	"Wood": "ecorce", "LightWood": "ecorce_claire",
	"Green": "feuillage", "DarkGreen": "feuillage_sombre",
	"White": "ecorce_bouleau", "Black": "ecorce_tache",
	"Orange": "feuillage_dore", "LightOrange": "feuillage_dore_clair",
	"Rock": "pierre", "Berry": "baie", "Leaves": "feuillage_sec",
	"Yellow": "fleur_jaune", "Cyan": "fleur_bleue", "Pink": "fleur_rose",
	"Mushroom_Top": "champignon", "Mushroom_Bottom": "champignon_pied",
}
PIN    = {"Green": "feuillage_pin", "DarkGreen": "feuillage_pin_sombre"}
SAULE  = {"Green": "feuillage_saule"}
BUISSON = {"Green": "feuillage_buisson"}
FOUGERE = {"Green": "feuillage_fougere", "DarkGreen": "feuillage_fougere_sombre"}
FLEUR  = {"Green": "tige"}
ROCHER = {"Green": "mousse"}
SOUCHE = {"Green": "mousse", "DarkGreen": "mousse"}

# nom du .fbx → (nom du .glb, hauteur cible en m, correspondances propres)
# La hauteur est mesurée du sol au sommet. Les maisons font 4 à 6 m.
MODELES = {
	# Feuillus — CommonTree_1 et _2 sont les « grands chênes » : canopée large.
	"CommonTree_1":  ("feuillu_large_1", 11.0, {}),
	"CommonTree_2":  ("feuillu_large_2", 12.5, {}),
	"CommonTree_3":  ("feuillu_haut",     9.5, {}),
	"CommonTree_4":  ("feuillu_rond",     7.5, {}),
	"CommonTree_5":  ("feuillu_jeune",    7.0, {}),
	"CommonTree_Autumn_2": ("feuillu_dore", 10.0, {}),
	"BirchTree_1":   ("bouleau_1",        9.0, {}),
	"BirchTree_5":   ("bouleau_2",       11.0, {}),
	"PineTree_2":    ("pin_1",           11.0, PIN),
	"PineTree_3":    ("pin_2",            9.5, PIN),
	"PineTree_4":    ("pin_3",           10.5, PIN),
	"Willow_2":      ("saule",            8.5, SAULE),
	# Sous-bois
	"Bush_1":        ("buisson_1",        1.7, BUISSON),
	"Bush_2":        ("buisson_2",        1.3, BUISSON),
	"BushBerries_1": ("buisson_baies",    1.5, BUISSON),
	"Plant_1":       ("fougere_basse",    0.55, FOUGERE),
	"Plant_3":       ("fougere",          0.85, FOUGERE),
	"Plant_4":       ("fougere_large",    0.9, FOUGERE),
	# Fleurs
	"Flowers":       ("fleurs_touffe",    0.6, FLEUR),
	"Plant_5":       ("fleurs_hautes",    0.75, FLEUR),
	# Rochers (taille de base ; decor_village.gd les agrandit)
	"Rock_1":        ("rocher_1",         0.9, {}),
	"Rock_4":        ("rocher_2",         1.2, {}),
	"Rock_Moss_2":   ("rocher_moussu_1",  0.65, ROCHER),
	"Rock_Moss_3":   ("rocher_moussu_2",  0.56, ROCHER),
	"Rock_Moss_5":   ("rocher_moussu_3",  0.58, ROCHER),
	"Rock_Moss_6":   ("rocher_moussu_4",  0.71, ROCHER),
	"Rock_Moss_7":   ("rocher_moussu_5",  0.77, ROCHER),
	# Bois mort
	"TreeStump_Moss": ("souche",          0.8, SOUCHE),
	"WoodLog_Moss":  ("tronc_couche",     0.9, SOUCHE),
}

_materiaux = {}


def materiau(nom):
	"""Un matériau Principled tout simple : couleur unie, mat, non métallique."""
	if nom in _materiaux:
		return _materiaux[nom]
	mat = bpy.data.materials.new(name=nom)
	r, v, b = (vers_lineaire(c) for c in PALETTE[nom])
	mat.diffuse_color = (r, v, b, 1.0)
	if mat.node_tree is None:
		mat.use_nodes = True
	noeuds = mat.node_tree.nodes
	bsdf = next((n for n in noeuds if n.type == "BSDF_PRINCIPLED"), None)
	if bsdf is None:
		bsdf = noeuds.new("ShaderNodeBsdfPrincipled")
		sortie = next((n for n in noeuds if n.type == "OUTPUT_MATERIAL"), None)
		if sortie is None:
			sortie = noeuds.new("ShaderNodeOutputMaterial")
		mat.node_tree.links.new(bsdf.outputs[0], sortie.inputs["Surface"])
	bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
	bsdf.inputs["Roughness"].default_value = 0.9
	bsdf.inputs["Metallic"].default_value = 0.0
	_materiaux[nom] = mat
	return mat


def nom_d_origine(mat):
	# Blender suffixe les doublons : « Green.001 » est le même « Green ».
	return mat.name.split(".")[0]


def traiter(nom_fbx, nom_glb, hauteur, propres):
	bpy.ops.wm.read_factory_settings(use_empty=True)
	_materiaux.clear()
	bpy.ops.import_scene.fbx(filepath=os.path.join(DOSSIER_SOURCES, nom_fbx + ".fbx"))
	objets = [o for o in bpy.context.scene.objects if o.type == "MESH"]
	for o in bpy.context.scene.objects:
		o.select_set(o.type == "MESH")
	bpy.context.view_layer.objects.active = objets[0]
	if len(objets) > 1:
		bpy.ops.object.join()
	obj = bpy.context.active_object
	# On « cuit » rotation et échelle de l'import FBX dans les sommets : le
	# maillage exporté est alors dans le bon repère, sans noeud intermédiaire.
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

	# 1. Les matériaux
	table = dict(DEFAUT)
	table.update(propres)
	for slot in obj.material_slots:
		if slot.material is None:
			continue
		origine = nom_d_origine(slot.material)
		if origine not in table:
			raise RuntimeError(f"{nom_fbx} : matériau inconnu « {origine} »")
		slot.material = materiau(table[origine])
	# Deux slots qui pointent vers le même matériau = deux surfaces inutiles
	# dans Godot (donc deux ordres de dessin). On les fusionne.
	bpy.ops.object.mode_set(mode="OBJECT")
	_fusionner_slots(obj)

	# 2. Le pied du tronc à l'origine
	donnees = obj.data
	zmin = min(v.co.z for v in donnees.vertices)
	zmax = max(v.co.z for v in donnees.vertices)
	pied = _pied_du_tronc(obj, zmin)
	echelle = hauteur / max(zmax - zmin, 0.001)
	for v in donnees.vertices:
		v.co = (v.co - Vector((pied.x, pied.y, 0.0))) * echelle
	donnees.update()

	# Rayon du tronc, une fois mis à l'échelle — à recopier dans ESSENCES
	# (decor_village.gd) pour la collision.
	rayon = _rayon_du_tronc(obj)

	# 3. Export
	dossier = os.path.join(DOSSIER_ASSETS, SOUS_DOSSIER)
	os.makedirs(dossier, exist_ok=True)
	obj.name = nom_glb
	bpy.ops.object.shade_flat()
	bpy.ops.export_scene.gltf(
		filepath=os.path.join(dossier, nom_glb + ".glb"),
		use_selection=True,
		export_format="GLB",
		export_apply=True,
	)
	larg = max(max(v.co.x for v in donnees.vertices) - min(v.co.x for v in donnees.vertices),
			   max(v.co.y for v in donnees.vertices) - min(v.co.y for v in donnees.vertices))
	print(f"OK  {nom_glb:18s} {len(donnees.polygons):5d} faces  "
		  f"{len(obj.material_slots)} surfaces  h={hauteur:.1f} m  "
		  f"largeur={larg:.1f} m  rayon_tronc={rayon:.2f} m")


def _fusionner_slots(obj):
	"""Regroupe les slots qui partagent le même matériau."""
	index_par_mat = {}
	remap = {}
	for i, slot in enumerate(obj.material_slots):
		cle = slot.material.name if slot.material else ""
		if cle not in index_par_mat:
			index_par_mat[cle] = i
		remap[i] = index_par_mat[cle]
	for p in obj.data.polygons:
		p.material_index = remap[p.material_index]
	# On retire les slots devenus vides, du dernier au premier.
	utilises = {p.material_index for p in obj.data.polygons}
	for i in reversed(range(len(obj.material_slots))):
		if i not in utilises:
			obj.active_material_index = i
			bpy.ops.object.material_slot_remove()


def _pied_du_tronc(obj, zmin):
	"""Centre (x, y) des sommets d'écorce proches du sol.

	Les arbres du pack ne sont pas tous centrés sur leur tronc (la canopée
	penche). On veut l'origine DANS le tronc : c'est là que decor_village.gd
	pose le cylindre de collision. Sans écorce (rocher, buisson), on prend le
	centre de la boîte englobante.
	"""
	ecorces = {i for i, s in enumerate(obj.material_slots)
			   if s.material and s.material.name.startswith("ecorce")}
	points = []
	if ecorces:
		for p in obj.data.polygons:
			if p.material_index in ecorces:
				for iv in p.vertices:
					co = obj.data.vertices[iv].co
					if co.z < zmin + 0.25:
						points.append(co)
	if not points:
		xs = [v.co.x for v in obj.data.vertices]
		ys = [v.co.y for v in obj.data.vertices]
		return Vector(((min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5, 0.0))
	somme = Vector((0.0, 0.0, 0.0))
	for co in points:
		somme += co
	return somme / len(points)


def _rayon_du_tronc(obj):
	"""Rayon moyen de l'écorce entre 0,5 m et 1,5 m de haut (0 si pas de tronc)."""
	ecorces = {i for i, s in enumerate(obj.material_slots)
			   if s.material and s.material.name.startswith("ecorce")}
	distances = []
	for p in obj.data.polygons:
		if p.material_index in ecorces:
			for iv in p.vertices:
				co = obj.data.vertices[iv].co
				if 0.5 < co.z < 1.5:
					distances.append((co.x ** 2 + co.y ** 2) ** 0.5)
	return sum(distances) / len(distances) if distances else 0.0


if __name__ == "__main__":
	# `-- nom1 nom2` en fin de ligne de commande : ne traiter que ceux-là.
	args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	for nom_fbx, (nom_glb, hauteur, propres) in MODELES.items():
		if args and nom_fbx not in args and nom_glb not in args:
			continue
		traiter(nom_fbx, nom_glb, hauteur, propres)
