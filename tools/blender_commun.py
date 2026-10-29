# tools/blender_commun.py
# Boîte à outils partagée par tous les scripts Blender de Gwanur.
#
# Les scripts de génération (gen_maison, gen_arbres, gen_aelith_v2,
# gen_personnages) partagent la même palette, la même conversion de couleurs et
# le même export. Tout ça vit ici, en un seul endroit.
#
# Pour l'importer depuis un script lancé par Blender, il faut d'abord ajouter
# le dossier tools/ au chemin de recherche Python — Blender ne le fait pas :
#
#     import sys, os
#     sys.path.append(os.path.dirname(os.path.abspath(__file__)))
#     from blender_commun import *
#
# ⚠ Quand Blender est lancé avec --python, `__file__` est bien le chemin du
# script, mais il n'est PAS ajouté à sys.path automatiquement.

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector

# ── Repères d'axes ────────────────────────────────────────────────────────────
# Blender est en Z-up, Godot en Y-up. L'export glTF convertit tout seul :
#   Blender +X → Godot +X     Blender +Z → Godot +Y     Blender -Y → Godot +Z
# Donc ce qu'on met en -Y ici regarde le SUD dans Godot.

# Calculé depuis l'emplacement de CE fichier (tools/ → ../assets/models) :
# un chemin écrit en dur enverrait les .glb dans un autre dossier que celui où
# le script est lancé (une copie du repo, un worktree git…).
DOSSIER_ASSETS = os.path.join(
	os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "models")

# ── Palette ───────────────────────────────────────────────────────────────────
# Les valeurs sont en sRGB, comme dans decor_village.gd. La conversion vers le
# linéaire attendu par Blender est faite par `materiau()`.

COULEURS = {
	# Bâti
	"torchis":     (0.86, 0.80, 0.68),
	"bois":        (0.42, 0.28, 0.18),
	"bois_clair":  (0.58, 0.42, 0.26),
	"tuile":       (0.55, 0.25, 0.16),
	"tuile_2":     (0.48, 0.30, 0.20),
	"pierre":      (0.62, 0.58, 0.50),
	"vitre":       (1.00, 0.80, 0.45),
	# Végétation
	"ecorce":      (0.36, 0.26, 0.19),
	"ecorce_pale": (0.78, 0.75, 0.68),   # bouleau
	# L'Aelith a l'écorce claire (LORE) — mais une claire CHAUDE : un gris-beige
	# neutre, sous le soleil doré, vire au rose saumon et se lit comme du béton.
	"ecorce_aelith": (0.66, 0.55, 0.42),
	"ecorce_aelith_sombre": (0.36, 0.27, 0.20),  # le fond des sillons
	"ecorce_aelith_doree": (0.80, 0.65, 0.44),   # les crêtes qui prennent le soleil
	"feuille":     (0.29, 0.49, 0.35),
	"feuille_clair": (0.40, 0.60, 0.38),
	"feuille_sombre": (0.21, 0.38, 0.28),
	"feuille_or":  (0.78, 0.65, 0.30),   # feuillage doré de l'Aelith
	"mousse":      (0.34, 0.47, 0.29),
	"aiguille":    (0.24, 0.40, 0.32),   # conifère
	# Personnages
	"peau":        (0.88, 0.72, 0.60),
	"cheveux_kael":(0.85, 0.80, 0.62),   # blond cendré, héritage elfique
	"cheveux_mira":(0.30, 0.20, 0.15),   # brun foncé
	"tunique_kael":(0.40, 0.55, 0.42),   # vert nature
	"tunique_mira":(0.62, 0.34, 0.24),   # auburn
	"cuir":        (0.45, 0.32, 0.22),
	"metal":       (0.55, 0.52, 0.48),
	"cuivre":      (0.72, 0.45, 0.25),   # le grappin de Mira
	"seve":        (0.55, 0.85, 0.60),   # les brassards de Sève de Kael
	"lueur":       (1.00, 0.85, 0.55),   # la Lanterne à Mémoire
	# PNJ — `tunique_pnj` est une couleur NEUTRE : Godot la remplace par la
	# couleur propre à chaque villageois (voir scripts/npcs/pnj.gd). Le NOM du
	# matériau est un contrat : ne pas le renommer.
	"tunique_pnj": (0.78, 0.74, 0.66),
	"lin":         (0.86, 0.80, 0.68),   # tablier, foulard
	"cheveux_blanc": (0.86, 0.84, 0.80), # barbe et cheveux de l'ancien
	"cheveux_chatain": (0.45, 0.30, 0.18),
	"cheveux_roux": (0.62, 0.32, 0.18),
	"feutre":      (0.36, 0.30, 0.24),   # chapeau du villageois
	# Props
	"bois_sombre": (0.30, 0.20, 0.13),
	"bois_mouille": (0.26, 0.19, 0.14),  # la roue à aubes, toujours humide
	"fer":         (0.30, 0.29, 0.28),   # ferrures, grille
	"plume":       (0.96, 0.95, 0.92),   # l'oiseau blanc
	"bec":         (0.90, 0.62, 0.25),
	"pierre_claire": (0.78, 0.70, 0.56),  # la stèle, la margelle
	"pierre_sombre": (0.52, 0.48, 0.42),
	"galet":       (0.66, 0.62, 0.55),
	"corde":       (0.72, 0.62, 0.44),
	"tuile_puits": (0.55, 0.25, 0.16),
	"or_grave":    (0.85, 0.68, 0.32),   # les runes de la stèle
}

_materiaux = {}


def vers_lineaire(c):
	"""sRGB → linéaire.

	Godot interprète les couleurs en sRGB, Blender les attend en linéaire, et
	le glTF transporte la valeur telle quelle. Sans cette conversion, tout
	ressort délavé dans le jeu (0.55 linéaire ≈ 0.76 à l'écran).
	"""
	return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def materiau(nom, emission=0.0):
	"""Un matériau Principled BSDF par couleur, réutilisé partout.

	`emission` > 0 fait briller la surface par elle-même (lanterne, vitrail).
	"""
	cle = (nom, emission)
	if cle in _materiaux:
		return _materiaux[cle]

	mat = bpy.data.materials.new(name=nom if emission == 0.0 else f"{nom}_lumineux")
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
	if emission > 0.0 and "Emission Color" in bsdf.inputs:
		bsdf.inputs["Emission Color"].default_value = (r, v, b, 1.0)
		bsdf.inputs["Emission Strength"].default_value = emission

	_materiaux[cle] = mat
	return mat


def vider_la_scene():
	"""Repart d'une scène propre. À appeler avant chaque modèle."""
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()
	for bloc in list(bpy.data.meshes):
		bpy.data.meshes.remove(bloc)


# ──────────────────────────────────────────────────────────────────────────────
# PRIMITIVES
# ──────────────────────────────────────────────────────────────────────────────


def _finaliser(bm, nom, position, rotation, couleur, emission=0.0):
	mesh = bpy.data.meshes.new(nom)
	bm.to_mesh(mesh)
	bm.free()
	objet = bpy.data.objects.new(nom, mesh)
	bpy.context.collection.objects.link(objet)
	objet.location = position
	objet.rotation_euler = rotation
	objet.data.materials.append(materiau(couleur, emission))
	return objet


def boite(nom, taille, position, couleur, rotation=(0, 0, 0), biseau=0.025,
		  tordu=0.0, emission=0.0):
	"""Une boîte aux arêtes biseautées.

	Le biseau est LE détail qui compte : un cube parfait n'a aucun liseré de
	lumière sur ses arêtes, d'où l'aspect « bloc ».
	`tordu` = amplitude en radians d'une rotation aléatoire, pour le côté
	« bâti à la main ».
	"""
	bm = bmesh.new()
	bmesh.ops.create_cube(bm, size=1.0)
	bmesh.ops.scale(bm, vec=Vector(taille), verts=bm.verts)
	if biseau > 0.0:
		# Le biseau ne peut pas dépasser la moitié de la plus petite dimension,
		# sinon la géométrie se replie sur elle-même.
		bmesh.ops.bevel(
			bm,
			geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
			offset=min(biseau, min(taille) * 0.45),
			segments=2,
			profile=0.5,
			affect="EDGES",
			clamp_overlap=True,
		)
	rot = tuple(r + random.uniform(-tordu, tordu) for r in rotation)
	return _finaliser(bm, nom, position, rot, couleur, emission)


def boule(nom, rayon, position, couleur, aplatissement=1.0, subdivisions=2,
		  rotation=(0, 0, 0), emission=0.0):
	"""Une icosphère — des facettes régulières, pas de pôles étirés.

	`subdivisions` : 1 = 80 faces (très facetté), 2 = 320, 3 = 1280.
	Pour du feuillage, 1 ou 2 suffisent largement et lisent mieux : les
	facettes attrapent la lumière et donnent le côté dessiné à la main.
	"""
	bm = bmesh.new()
	bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=rayon)
	bmesh.ops.scale(bm, vec=Vector((1.0, 1.0, aplatissement)), verts=bm.verts)
	return _finaliser(bm, nom, position, rotation, couleur, emission)


def cylindre(nom, rayon_bas, rayon_haut, hauteur, position, couleur,
			 segments=8, rotation=(0, 0, 0), emission=0.0):
	"""Un tronc de cône, posé sur sa base (l'origine est au PIED, pas au centre).

	C'est plus pratique pour empiler des segments de tronc ou de branche.
	"""
	bm = bmesh.new()
	bmesh.ops.create_cone(
		bm,
		cap_ends=True,
		cap_tris=False,
		segments=segments,
		radius1=rayon_bas,
		radius2=rayon_haut,
		depth=hauteur,
	)
	# create_cone centre la forme sur l'origine : on la remonte d'une demi-hauteur.
	bmesh.ops.translate(bm, vec=Vector((0, 0, hauteur * 0.5)), verts=bm.verts)
	return _finaliser(bm, nom, position, rotation, couleur, emission)


def branche(nom, depart, arrivee, rayon_depart, rayon_arrivee, couleur, segments=6):
	"""Un cylindre tendu entre deux points de l'espace.

	Évite de calculer les rotations à la main : on donne les deux bouts.
	"""
	depart = Vector(depart)
	arrivee = Vector(arrivee)
	direction = arrivee - depart
	longueur = direction.length
	if longueur < 0.001:
		return None

	objet = cylindre(nom, rayon_depart, rayon_arrivee, longueur, depart, couleur, segments)
	# to_track_quat aligne l'axe Z de l'objet sur la direction voulue.
	objet.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
	return objet


# ──────────────────────────────────────────────────────────────────────────────
# EXPORT
# ──────────────────────────────────────────────────────────────────────────────


def exporter(sous_dossier, nom_fichier, lisse=False):
	"""Fusionne tous les objets de la scène et exporte en .glb.

	Un seul objet fusionné = un seul noeud à afficher côté Godot, au lieu de
	cent. Les matériaux sont conservés : l'objet garde une surface par couleur.
	"""
	dossier = os.path.join(DOSSIER_ASSETS, sous_dossier)
	os.makedirs(dossier, exist_ok=True)
	chemin = os.path.join(dossier, nom_fichier)

	bpy.ops.object.select_all(action="SELECT")
	selection = bpy.context.selected_objects
	if not selection:
		raise RuntimeError(f"Rien à exporter pour {nom_fichier}")
	bpy.context.view_layer.objects.active = selection[0]
	bpy.ops.object.join()
	bpy.context.active_object.name = os.path.splitext(nom_fichier)[0]

	# Normales dures par défaut : le style est facetté, pas lissé.
	if lisse:
		bpy.ops.object.shade_smooth()
	else:
		bpy.ops.object.shade_flat()

	bpy.ops.export_scene.gltf(
		filepath=chemin,
		use_selection=True,
		export_format="GLB",
		export_apply=True,
	)
	nb = len(bpy.context.active_object.data.polygons)
	print(f"OK  {sous_dossier}/{nom_fichier}  ({nb} faces)")
	return nb
