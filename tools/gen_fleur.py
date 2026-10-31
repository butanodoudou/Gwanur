# tools/gen_fleur.py — la fleur sans nom, de l'autre côté du pont
#
# La même fleur que celle trouvée sur l'oreiller d'Aelindra (intro). Elle
# pousse dans le bief, là où leur mère s'est assise la nuit de son départ
# (voir docs/LORE.md, « La fleur sans nom »).
#
# Trois modèles :
#
#   modèle          posé par                          origine du modèle
#   ─────────────── ───────────────────────────────── ─────────────────────
#   fleur           scripts/zones/fleur_bief.gd       au SOL, sous la tige
#   fleur_touffe    fleur_bief.gd (près du pont)      au SOL, centre de la touffe
#   petales         fleur_bief.gd (le long du bief)   au SOL, centre de la jonchée
#
# LISIBILITÉ À 9 M : la vraie fleur serait minuscule. Ici elle est
# volontairement trop grande (≈ 1 m, corolle de 0,7 m) et sa corolle LUIT
# doucement (matériau émissif) : depuis le pont, on doit la voir sans la
# chercher. Couleur « blanc de lune » légèrement lilas — aucune autre pièce du
# village n'a cette teinte (l'oiseau est blanc chaud, la lanterne dorée, la
# sève verte).
#
# Les matériaux de la tige et des feuilles ne contiennent PAS « feuill » dans
# leur nom : la stylisation (scripts/rendu/stylisation.gd) traiterait sinon la
# fleur comme un arbre (vent, normales sphériques).
#
# Usage :
#   blender --background --python tools/gen_fleur.py
# Sortie :
#   assets/models/props/fleur.glb, fleur_touffe.glb, petales.glb

import bmesh
import bpy
import math
import os
import random
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import COULEURS, _finaliser, boule, branche, vider_la_scene, exporter

SOUS_DOSSIER = "props"

# Les couleurs propres à la fleur, ajoutées à la palette commune pour ce
# script seulement (sRGB, converties en linéaire par materiau()).
COULEURS.update({
	"petale_lune": (0.90, 0.88, 0.98),   # blanc de lune, à peine lilas
	"coeur_lune":  (0.74, 0.80, 1.00),   # le coeur, bleu pâle, qui luit plus fort
	"etamine":     (0.96, 0.90, 0.70),   # pointes des étamines, or très pâle
	"tige_fleur":  (0.30, 0.46, 0.34),
	"limbe_fleur": (0.36, 0.56, 0.40),   # les feuilles (pas « feuille » : voir l'en-tête)
})

# Émission : assez pour qu'elle se détache dans l'ombre de la palissade,
# pas assez pour éclairer quoi que ce soit (ce n'est pas une lanterne).
EMISSION_PETALE = 0.9
EMISSION_COEUR = 2.2


def petale(nom, base, angle, inclinaison, longueur, largeur, couleur,
		   emission=0.0, epaisseur=0.018):
	"""Un pétale : une icosphère aplatie et allongée, dont la BASE est à `base`.

	`angle`       : direction du pétale autour de l'axe vertical (radians)
	`inclinaison` : 0 = à plat, π/2 = dressé à la verticale
	"""
	bm = bmesh.new()
	bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
	# Allongé le long de +Y, très fin en Z : une goutte plate.
	bmesh.ops.scale(bm, vec=Vector((largeur * 0.5, longueur * 0.5, epaisseur)), verts=bm.verts)
	# Un pétale est plus large au bout qu'à la base : on resserre le côté -Y.
	for v in bm.verts:
		t = (v.co.y / (longueur * 0.5) + 1.0) * 0.5      # 0 à la base, 1 au bout
		v.co.x *= 0.45 + 0.55 * math.sin(min(t * 1.25, 1.0) * math.pi * 0.5)
		# Le bout se recourbe un peu vers le haut : la corolle est une coupe.
		v.co.z += (t ** 2) * longueur * 0.12
	# La base à l'origine
	bmesh.ops.translate(bm, vec=Vector((0, longueur * 0.5, 0)), verts=bm.verts)
	# Rotation : d'abord on relève le pétale (autour de X), puis on le tourne
	# autour de la tige (autour de Z). L'ordre Euler XYZ de Blender fait ça.
	return _finaliser(bm, nom, Vector(base), (inclinaison, 0.0, angle - math.pi * 0.5),
					  couleur, emission)


def feuille_lanceolee(nom, base, angle, inclinaison, longueur, largeur):
	"""Une feuille longue et fine, comme celles des lys, qui part du pied."""
	return petale(nom, base, angle, inclinaison, longueur, largeur, "limbe_fleur",
				  epaisseur=0.012)


def corolle(prefixe, centre, rayon, nb_petales, ouverture, decalage=0.0):
	"""Une corolle : deux couronnes de pétales en coupe, un coeur, des étamines.

	`ouverture` : inclinaison des pétales (petit = coupe fermée, grand = étoile).
	"""
	centre = Vector(centre)
	for i in range(nb_petales):
		a = decalage + i * math.tau / nb_petales + random.uniform(-0.08, 0.08)
		petale(f"{prefixe}_Petale_{i}", centre, a, ouverture + random.uniform(-0.08, 0.08),
			   rayon * random.uniform(0.95, 1.05), rayon * 0.62, "petale_lune",
			   emission=EMISSION_PETALE)
	# Seconde couronne, plus courte et plus dressée, décalée d'un demi-pétale :
	# la fleur paraît pleine vue de côté.
	for i in range(nb_petales):
		a = decalage + (i + 0.5) * math.tau / nb_petales
		petale(f"{prefixe}_Interieur_{i}", centre + Vector((0, 0, 0.01)), a,
			   ouverture + 0.35, rayon * 0.72, rayon * 0.5, "petale_lune",
			   emission=EMISSION_PETALE)
	boule(f"{prefixe}_Coeur", rayon * 0.16, centre + Vector((0, 0, rayon * 0.08)),
		  "coeur_lune", aplatissement=0.7, subdivisions=2, emission=EMISSION_COEUR)
	for i in range(5):
		a = i * math.tau / 5 + 0.3
		pointe = centre + Vector((math.cos(a) * rayon * 0.22, math.sin(a) * rayon * 0.22,
								  rayon * 0.42))
		branche(f"{prefixe}_Etamine_{i}", centre, pointe, 0.006, 0.004, "etamine", segments=4)
		boule(f"{prefixe}_Pollen_{i}", 0.014, pointe, "etamine", subdivisions=1,
			  emission=0.8)


def tige(prefixe, pied, tete, epaisseur=0.022, courbure=0.06):
	"""Une tige légèrement arquée, en trois segments."""
	pied, tete = Vector(pied), Vector(tete)
	milieu = (pied + tete) * 0.5 + Vector((courbure, courbure * 0.5, 0))
	points = [pied, pied.lerp(milieu, 0.6), milieu, milieu.lerp(tete, 0.5), tete]
	for i in range(len(points) - 1):
		e = epaisseur * (1.0 - 0.25 * i / len(points))
		branche(f"{prefixe}_Tige_{i}", points[i], points[i + 1], e, e * 0.9,
				"tige_fleur", segments=6)
	# Le calice : une petite coupe verte sous la corolle
	boule(f"{prefixe}_Calice", epaisseur * 2.0, tete - Vector((0, 0, epaisseur)),
		  "tige_fleur", aplatissement=0.6, subdivisions=1)


# ──────────────────────────────────────────────────────────────────────────────


def fleur():
	"""LA fleur : une hampe d'un mètre, une corolle penchée vers le sud (le pont),
	et un bouton qui n'a pas encore ouvert."""
	tete = Vector((0.05, -0.08, 1.0))
	tige("Hampe", (0, 0, 0), tete, epaisseur=0.03, courbure=0.08)
	# Corolle légèrement tournée vers -Y (= le SUD dans Godot, côté pont)
	corolle("Fleur", tete, 0.34, 6, 0.9)
	# Un bouton fermé, sur une tige plus courte : la fleur vit, elle continue.
	bouton = Vector((-0.22, 0.1, 0.64))
	tige("Bouton", (-0.03, 0.01, 0.0), bouton, epaisseur=0.018, courbure=-0.06)
	for i in range(3):
		petale(f"Bouton_Petale_{i}", bouton, i * math.tau / 3, 1.35, 0.15, 0.09,
			   "petale_lune", emission=EMISSION_PETALE * 0.6)
	# Les feuilles, en rosette au pied
	for i in range(6):
		a = i * math.tau / 6 + random.uniform(-0.2, 0.2)
		feuille_lanceolee(f"Feuille_{i}", (0, 0, 0.02), a, random.uniform(0.45, 0.8),
						  random.uniform(0.42, 0.55), 0.1)
	# Un peu de mousse au pied : elle est posée sur un sol vivant, pas sur rien.
	for i in range(4):
		a = random.uniform(0, math.tau)
		boule(f"Mousse_{i}", random.uniform(0.06, 0.1),
			  (math.cos(a) * 0.12, math.sin(a) * 0.12, 0.02), "mousse",
			  aplatissement=0.45, subdivisions=1)


def fleur_touffe():
	"""Une touffe de trois petites fleurs et de boutons, pour attirer l'oeil
	depuis le pont. Moitié moins haute que LA fleur : elle guide, elle ne
	remplace pas."""
	for k, (x, y, h) in enumerate([(0.0, 0.0, 0.6), (0.3, 0.16, 0.46), (-0.2, 0.28, 0.4)]):
		tete = Vector((x + 0.03, y - 0.04, h))
		tige(f"T{k}", (x, y, 0), tete, epaisseur=0.018, courbure=0.04)
		corolle(f"T{k}", tete, 0.19, 6, 1.0, decalage=k * 0.4)
		for i in range(3):
			a = i * math.tau / 3 + k
			feuille_lanceolee(f"T{k}_Feuille_{i}", (x, y, 0.02), a, 0.6, 0.28, 0.07)
	# Deux boutons fermés
	for k, (x, y) in enumerate([(0.14, -0.25), (-0.34, -0.07)]):
		bouton = Vector((x, y, 0.3))
		tige(f"B{k}", (x, y, 0), bouton, epaisseur=0.013, courbure=0.03)
		for i in range(3):
			petale(f"B{k}_Petale_{i}", bouton, i * math.tau / 3, 1.4, 0.1, 0.06,
				   "petale_lune", emission=EMISSION_PETALE * 0.6)


def petales():
	"""Des pétales tombés, couchés dans l'herbe, sur une bande de 3 × 1 m le
	long de X : posés en file entre le pont et la fleur, ils dessinent un
	chemin, comme si quelqu'un était passé par là en en semant."""
	for i in range(14):
		x = random.uniform(-1.5, 1.5)
		y = random.uniform(-0.45, 0.45)
		petale(f"Tombe_{i}", (x, y, 0.025), random.uniform(0, math.tau),
			   random.uniform(0.0, 0.15), random.uniform(0.09, 0.14), 0.07,
			   "petale_lune", emission=EMISSION_PETALE * 0.8, epaisseur=0.01)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	total = 0
	for nom_fichier, graine, fabrique in [
		("fleur.glb", 61, fleur),
		("fleur_touffe.glb", 62, fleur_touffe),
		("petales.glb", 63, petales),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		total += exporter(SOUS_DOSSIER, nom_fichier, lisse=False)
	print(f"Total fleur : {total} faces")
