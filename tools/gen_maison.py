# tools/gen_maison.py — Maisons de Sylvara (Gwanur)
#
# Génère des maisons de village en GLB, à la place des boîtes + prismes
# procéduraux de `scripts/zones/decor_village.gd`.
#
# CE QUI FAIT LA DIFFÉRENCE (et ce n'est pas le nombre de polygones) :
#   1. Les ARÊTES BISEAUTÉES. Un cube parfait n'existe pas dans la nature :
#      ses arêtes vives ne captent aucune lumière, d'où l'aspect « bloc ».
#      Un biseau de 2 cm crée un liseré clair sur chaque arête. C'est LE
#      changement qui fait le plus, pour presque rien.
#   2. La SILHOUETTE. Débord de toit, cheminée, auvent : des décrochements
#      qui se lisent en ombre chinoise, de loin.
#   3. L'IRRÉGULARITÉ. Chaque poutre est tournée de un ou deux degrés au
#      hasard. Construit à la main, pas sorti d'une imprimante.
#   4. Le toit en RANGS DE BARDEAUX, pas une pente lisse.
#
# On reste en style Ghibli (formes simples, couleurs franches) — pas en
# photoréalisme, qui jurerait avec l'ART_DIRECTION.md et les personnages.
#
# Usage :
#   blender --background --python tools/gen_maison.py
# Sortie :
#   assets/models/environnement/maison_a.glb   (maison d'habitation)
#   assets/models/environnement/maison_b.glb   (variante, plus petite)
#   assets/models/environnement/moulin.glb     (le moulin de Brennan)

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector

# ── Repères d'axes ────────────────────────────────────────────────────────────
# Blender est en Z-up, Godot en Y-up. L'export glTF convertit tout seul :
#   Blender +X → Godot +X     Blender +Z → Godot +Y     Blender -Y → Godot +Z
# Donc ce qu'on met en -Y ici regarde le SUD dans Godot : c'est la façade que
# les joueurs voient en arrivant dans le village.

DOSSIER = r"C:\Users\PC\Documents\repo_git\Gwanur\assets\models\environnement"
os.makedirs(DOSSIER, exist_ok=True)

# ── Palette (identique à decor_village.gd) ────────────────────────────────────

COULEURS = {
	"torchis":   (0.86, 0.80, 0.68),
	"bois":      (0.42, 0.28, 0.18),
	"bois_clair":(0.58, 0.42, 0.26),
	"tuile":     (0.55, 0.25, 0.16),
	"tuile_2":   (0.48, 0.30, 0.20),
	"pierre":    (0.62, 0.58, 0.50),
	"vitre":     (1.00, 0.80, 0.45),
}

_materiaux = {}


def vers_lineaire(c):
	"""sRGB → linéaire.

	Les couleurs ci-dessus sont celles de `decor_village.gd`, où Godot les
	interprète en sRGB. Blender, lui, attend du linéaire, et le glTF transporte
	la valeur telle quelle. Sans cette conversion, toutes les couleurs
	ressortent délavées dans le jeu (0.55 linéaire ≈ 0.76 à l'écran).
	"""
	return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def materiau(nom):
	"""Un matériau Principled BSDF par couleur, réutilisé partout."""
	if nom in _materiaux:
		return _materiaux[nom]
	mat = bpy.data.materials.new(name=nom)
	r, v, b = (vers_lineaire(c) for c in COULEURS[nom])
	mat.diffuse_color = (r, v, b, 1.0)

	# Blender 5 crée déjà un arbre de noeuds, et le nom du noeud Principled a
	# changé selon les versions : on le retrouve par son TYPE, jamais par son nom.
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
	bsdf.inputs["Roughness"].default_value = 0.85
	bsdf.inputs["Metallic"].default_value = 0.0
	if nom == "vitre" and "Emission Color" in bsdf.inputs:
		# Les fenêtres sont allumées : l'émission est exportée en glTF et
		# Godot l'affiche telle quelle, sans réglage supplémentaire.
		bsdf.inputs["Emission Color"].default_value = (r, v, b, 1.0)
		bsdf.inputs["Emission Strength"].default_value = 1.5
	_materiaux[nom] = mat
	return mat


def vider_la_scene():
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()
	for bloc in list(bpy.data.meshes):
		bpy.data.meshes.remove(bloc)


def boite(nom, taille, position, couleur, rotation=(0, 0, 0), biseau=0.025, tordu=0.0):
	"""Une boîte aux arêtes biseautées.

	`tordu` = amplitude en radians d'une rotation aléatoire ajoutée sur chaque
	axe. C'est ce qui donne le côté « bâti à la main » : rien n'est parfaitement
	d'équerre dans un village.
	"""
	mesh = bpy.data.meshes.new(nom)
	objet = bpy.data.objects.new(nom, mesh)
	bpy.context.collection.objects.link(objet)

	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	bmesh.ops.scale(bm, vec=Vector(taille), verts=bm.verts)

	if biseau > 0.0:
		# Le biseau ne peut pas dépasser la moitié de la plus petite dimension,
		# sinon la géométrie se replie sur elle-même.
		limite = min(taille) * 0.45
		bmesh.ops.bevel(
			bm,
			geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
			offset=min(biseau, limite),
			segments=2,
			profile=0.5,
			affect="EDGES",
			clamp_overlap=True,
		)

	bm.to_mesh(mesh)
	bm.free()

	objet.location = position
	objet.rotation_euler = (
		rotation[0] + random.uniform(-tordu, tordu),
		rotation[1] + random.uniform(-tordu, tordu),
		rotation[2] + random.uniform(-tordu, tordu),
	)
	objet.data.materials.append(materiau(couleur))
	return objet


# ──────────────────────────────────────────────────────────────────────────────
# ÉLÉMENTS D'ARCHITECTURE
# ──────────────────────────────────────────────────────────────────────────────


def toit(largeur, profondeur, hauteur_mur, hauteur_toit, couleur, debord=0.5):
	"""Toit à deux pentes, en rangs de bardeaux.

	Le faîtage court le long de Y. Chaque pente est faite de rangs successifs
	qui se chevauchent, comme de vraies tuiles de bois — au lieu d'une pente
	lisse qui se lit immédiatement comme une forme 3D générée.
	"""
	demi_l = largeur * 0.5 + debord
	pente  = math.atan2(hauteur_toit, demi_l)
	long_pente = math.hypot(demi_l, hauteur_toit)
	rangs = 7
	pas = long_pente / rangs

	for cote in (-1, 1):
		for i in range(rangs):
			# Distance le long de la pente, mesurée depuis le bas.
			d = (i + 0.5) * pas
			x = cote * (demi_l - math.cos(pente) * d)
			z = hauteur_mur + math.sin(pente) * d
			# Chaque rang déborde un peu sur celui du dessous : l'ombre portée
			# entre deux rangs est ce qui dessine la texture du toit.
			# Rotation autour de Y : pour la pente de droite (cote=+1) l'axe X
			# du rang doit descendre vers l'extérieur, d'où l'angle +pente ;
			# c'est l'inverse à gauche. Un signe faux ici et tous les rangs
			# partent en croix — le toit a l'air effondré.
			boite(
				f"Bardeaux_{cote}_{i}",
				(pas * 1.12, profondeur + debord * 2.0, 0.14),
				(x, 0, z),
				couleur,
				rotation=(0, cote * pente, 0),
				biseau=0.02,
				tordu=0.0015,
			)

	# Poutre de faîtage
	boite("Faitage", (0.28, profondeur + debord * 2.2, 0.24),
		  (0, 0, hauteur_mur + hauteur_toit + 0.02), "bois", biseau=0.05)

	# Pignons : le triangle de mur sous chaque pente, aux deux bouts. On
	# l'approche par un escalier de lamelles — invisible une fois biseauté.
	for bout in (-1, 1):
		for i in range(6):
			t = (i + 0.5) / 6.0
			largeur_i = largeur * (1.0 - t)
			boite(
				f"Pignon_{bout}_{i}",
				(largeur_i, 0.22, hauteur_toit / 6.0 + 0.04),
				(0, bout * profondeur * 0.5, hauteur_mur + hauteur_toit * t),
				"torchis",
				biseau=0.015,
			)


def colombage(largeur, profondeur, hauteur, couleur="bois"):
	"""Les poutres apparentes plaquées sur les murs de torchis."""
	dl, dp = largeur * 0.5, profondeur * 0.5
	ep = 0.13  # les poutres dépassent du mur de 13 cm

	# Poteaux d'angle
	for sx in (-1, 1):
		for sy in (-1, 1):
			boite("Poteau", (0.26, 0.26, hauteur),
				  (sx * dl, sy * dp, hauteur * 0.5), couleur, biseau=0.04, tordu=0.01)

	# Sablières haute et basse, sur les quatre faces
	for z in (0.12, hauteur - 0.14):
		boite("Sabliere", (largeur + 0.1, ep, 0.26), (0, -dp, z), couleur, tordu=0.006)
		boite("Sabliere", (largeur + 0.1, ep, 0.26), (0,  dp, z), couleur, tordu=0.006)
		boite("Sabliere", (ep, profondeur + 0.1, 0.26), (-dl, 0, z), couleur, tordu=0.006)
		boite("Sabliere", (ep, profondeur + 0.1, 0.26), ( dl, 0, z), couleur, tordu=0.006)

	# Croix de Saint-André sur les côtés : deux diagonales. C'est le détail qui
	# dit « médiéval » plus fort que n'importe quelle texture.
	diag = math.hypot(profondeur * 0.8, hauteur * 0.8)
	angle = math.atan2(hauteur * 0.8, profondeur * 0.8)
	for sx in (-1, 1):
		for sens in (-1, 1):
			boite("Croix", (ep, diag, 0.2), (sx * dl, 0, hauteur * 0.5), couleur,
				  rotation=(sens * angle, 0, 0), biseau=0.03, tordu=0.01)


def fenetre(position, taille=(0.95, 1.05), rotation_z=0.0):
	"""Un cadre de bois, une croisée, et une vitre allumée en retrait."""
	l, h = taille
	x, y, z = position
	# Le vitrage est légèrement en retrait : l'encadrement projette une ombre
	# sur lui, ce qui creuse la façade au lieu de la laisser plate.
	sens = -1.0 if y < 0 else 1.0
	if rotation_z != 0.0:
		sens = -1.0 if x < 0 else 1.0

	def place(dx, dz, taille_3d):
		if rotation_z == 0.0:
			return (x + dx, y, z + dz), taille_3d
		return (x, y + dx, z + dz), (taille_3d[1], taille_3d[0], taille_3d[2])

	pos, tai = place(0, 0, (l, 0.10, h))
	boite("Vitre", tai, (pos[0] - sens * 0.02 if rotation_z else pos[0],
						 pos[1] - sens * 0.02 if not rotation_z else pos[1],
						 pos[2]), "vitre", biseau=0.01)

	# Encadrement : deux montants, un linteau, un appui
	for dx in (-l * 0.5 - 0.07, l * 0.5 + 0.07):
		pos, tai = place(dx, 0, (0.16, 0.22, h + 0.3))
		boite("Montant", tai, pos, "bois_clair", biseau=0.03)
	for dz in (-h * 0.5 - 0.1, h * 0.5 + 0.1):
		pos, tai = place(0, dz, (l + 0.4, 0.24, 0.18))
		boite("Linteau", tai, pos, "bois_clair", biseau=0.03)
	# Croisée
	pos, tai = place(0, 0, (0.08, 0.2, h))
	boite("Croisee", tai, pos, "bois_clair", biseau=0.02)
	pos, tai = place(0, 0, (l, 0.2, 0.08))
	boite("Croisee", tai, pos, "bois_clair", biseau=0.02)


def porte(position, largeur=1.15, hauteur=2.1):
	x, y, z = position
	# Planches verticales : quatre lames au lieu d'un panneau plein.
	for i in range(4):
		dx = (i - 1.5) * (largeur / 4.0)
		boite("Planche", (largeur / 4.0 - 0.03, 0.12, hauteur),
			  (x + dx, y, z + hauteur * 0.5), "bois", biseau=0.02, tordu=0.004)
	# Traverses et encadrement
	for dz in (hauteur * 0.25, hauteur * 0.8):
		boite("Traverse", (largeur, 0.14, 0.14), (x, y - 0.02, z + dz), "bois_clair", biseau=0.03)
	for dx in (-largeur * 0.5 - 0.1, largeur * 0.5 + 0.1):
		boite("Chambranle", (0.2, 0.26, hauteur + 0.3),
			  (x + dx, y, z + hauteur * 0.5), "bois_clair", biseau=0.04)
	boite("Linteau", (largeur + 0.6, 0.3, 0.22), (x, y, z + hauteur + 0.15), "bois_clair", biseau=0.04)
	# Marche de pierre
	boite("Marche", (largeur + 0.7, 0.7, 0.16), (x, y - 0.3, 0.08), "pierre", biseau=0.04)
	# Petit auvent au-dessus de la porte
	boite("Auvent", (largeur + 1.0, 0.8, 0.12), (x, y - 0.35, z + hauteur + 0.5),
		  "bois", rotation=(0.22, 0, 0), biseau=0.03)
	for dx in (-largeur * 0.5 - 0.2, largeur * 0.5 + 0.2):
		boite("Aisselier", (0.12, 0.55, 0.12), (x + dx, y - 0.25, z + hauteur + 0.35),
			  "bois", rotation=(-0.6, 0, 0), biseau=0.02)


def cheminee(position, hauteur_mur, hauteur_toit):
	x, y = position
	haut = hauteur_mur + hauteur_toit + 0.9
	boite("Cheminee", (0.85, 0.85, haut), (x, y, haut * 0.5), "pierre", biseau=0.05, tordu=0.008)
	boite("Couronnement", (1.15, 1.15, 0.22), (x, y, haut + 0.05), "pierre", biseau=0.05)


def soubassement(largeur, profondeur, hauteur=0.55):
	"""Base en pierre. Une maison qui sort du sol sans transition flotte."""
	boite("Soubassement", (largeur + 0.25, profondeur + 0.25, hauteur),
		  (0, 0, hauteur * 0.5), "pierre", biseau=0.06)
	# Quelques pierres saillantes pour casser la ligne
	for i in range(8):
		angle = random.uniform(0, math.tau)
		boite(
			f"Pierre_{i}",
			(random.uniform(0.3, 0.6), random.uniform(0.25, 0.5), random.uniform(0.2, 0.35)),
			(
				math.cos(angle) * largeur * 0.5,
				math.sin(angle) * profondeur * 0.5,
				random.uniform(0.15, hauteur - 0.1),
			),
			"pierre",
			rotation=(0, 0, random.uniform(0, math.tau)),
			biseau=0.04,
		)


# ──────────────────────────────────────────────────────────────────────────────
# ASSEMBLAGES
# ──────────────────────────────────────────────────────────────────────────────


def maison(largeur, profondeur, hauteur, teinte_toit="tuile", avec_cheminee=True):
	base = 0.55
	h_toit = hauteur * 0.62

	soubassement(largeur, profondeur, base)

	# Le corps en torchis. Il monte depuis le soubassement.
	boite("Murs", (largeur, profondeur, hauteur),
		  (0, 0, base + hauteur * 0.5), "torchis", biseau=0.05)

	colombage(largeur, profondeur, hauteur)
	# Le colombage est dessiné à partir de z=0 : on le remonte d'un cran.
	for obj in bpy.context.collection.objects:
		if obj.name.startswith(("Poteau", "Sabliere", "Croix")):
			obj.location.z += base

	# Toit
	objets_avant = set(bpy.context.collection.objects)
	toit(largeur, profondeur, hauteur, h_toit, teinte_toit)
	for obj in bpy.context.collection.objects:
		if obj not in objets_avant:
			obj.location.z += base

	# Façade sud (-Y dans Blender = +Z dans Godot)
	façade = -profondeur * 0.5 - 0.05
	porte((0, façade, base))
	fenetre((-largeur * 0.30, façade, base + hauteur * 0.68))
	fenetre(( largeur * 0.30, façade, base + hauteur * 0.68))
	# Une fenêtre sur chaque pignon
	fenetre((-largeur * 0.5 - 0.05, 0, base + hauteur * 0.6), rotation_z=math.pi / 2)
	fenetre(( largeur * 0.5 + 0.05, 0, base + hauteur * 0.6), rotation_z=math.pi / 2)

	if avec_cheminee:
		cheminee((largeur * 0.32, profondeur * 0.3), base + hauteur, h_toit)


def moulin(largeur, profondeur, hauteur):
	"""Le moulin de Brennan : même vocabulaire, plus haut, avec sa roue."""
	maison(largeur, profondeur, hauteur, teinte_toit="tuile_2")

	# Galerie de bois au premier étage
	for sy in (-1, 1):
		boite("Galerie", (largeur + 0.5, 0.35, 0.16),
			  (0, sy * (profondeur * 0.5 + 0.2), hauteur * 0.62), "bois_clair", biseau=0.03)
		for i in range(7):
			x = -largeur * 0.5 + i * (largeur / 6.0)
			boite("Balustre", (0.1, 0.1, 0.6),
				  (x, sy * (profondeur * 0.5 + 0.2), hauteur * 0.62 + 0.38), "bois", biseau=0.02)

	# Potence de grenier sur le pignon ouest : la poutre qui dépasse du toit,
	# avec sa poulie, pour hisser les sacs de grain à l'étage.
	# (Pas de roue à aubes ici : le moulin est loin du ruisseau, et le Puzzle 3
	# a déjà la sienne. Deux roues à trente mètres d'écart embrouilleraient.)
	x_potence = -largeur * 0.5 - 1.3
	z_potence = hauteur + hauteur * 0.62 * 0.45
	boite("Potence", (3.0, 0.3, 0.3), (x_potence + 1.0, 0, z_potence), "bois", biseau=0.05)
	boite("Jambe", (0.24, 0.24, 1.7), (x_potence + 2.0, 0, z_potence - 0.85), "bois",
		  rotation=(0, 0.55, 0), biseau=0.04)
	boite("Poulie", (0.5, 0.18, 0.5), (x_potence, 0, z_potence - 0.35), "bois_clair", biseau=0.08)
	boite("Corde", (0.07, 0.07, 2.4), (x_potence, 0, z_potence - 1.6), "bois_clair", biseau=0.01)
	boite("Sac", (0.7, 0.7, 0.8), (x_potence, 0, z_potence - 3.0), "torchis", biseau=0.12, tordu=0.06)

	# Trappe de chargement sous la potence
	boite("Trappe", (0.3, 1.3, 1.5), (-largeur * 0.5 - 0.05, 0, hauteur * 0.62), "bois", biseau=0.04)


def exporter(nom_fichier):
	chemin = os.path.join(DOSSIER, nom_fichier)
	bpy.ops.object.select_all(action="SELECT")
	# On fusionne tout en un seul objet : Godot n'aura qu'un noeud à afficher
	# au lieu de cent, et le rendu est nettement plus léger.
	bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
	bpy.ops.object.join()
	bpy.context.active_object.name = os.path.splitext(nom_fichier)[0]

    # Les normales doivent rester dures : le style est facetté, pas lissé.
	bpy.ops.object.shade_flat()

	bpy.ops.export_scene.gltf(
		filepath=chemin,
		use_selection=True,
		export_format="GLB",
		export_apply=True,
	)
	nb = len(bpy.context.active_object.data.polygons)
	print(f"OK  {nom_fichier}  ({nb} faces)")


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	# Les tailles reprennent celles de MAISONS dans zone1.gd, en enlevant la
	# hauteur du toit qui est maintenant construite par-dessus les murs.
	for nom, graine, fabrique in [
		("maison_a.glb", 11, lambda: maison(7.0, 6.5, 3.6)),
		("maison_b.glb", 23, lambda: maison(5.5, 5.0, 3.2, teinte_toit="tuile_2")),
		("moulin.glb",   37, lambda: moulin(7.5, 7.0, 5.4)),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		exporter(nom)
