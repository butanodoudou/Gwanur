# tools/gen_arbres.py — Les arbres de Sylvara
#
# Remplace les arbres « tronc + 3 bulles » de decor_village.gd.
#
# CE QUI FAIT QU'UN ARBRE RESSEMBLE À UN ARBRE
#   1. L'EMPATTEMENT. Un tronc qui sort du sol comme un poteau planté n'est
#      jamais crédible. De vraies racines qui s'évasent à la base, oui.
#   2. LA RAMIFICATION. Des branches qui partent du tronc et se divisent, avec
#      du feuillage AU BOUT — pas une boule posée sur un bâton.
#   3. LA CANOPÉE EN GRAPPES. Plusieurs masses de tailles et de teintes
#      différentes, pas une sphère unique : c'est la silhouette découpée qui
#      donne le côté dessiné à la main.
#   4. L'ASYMÉTRIE. Chaque arbre penche un peu et n'a pas deux branches
#      identiques.
#
# Usage :
#   blender --background --python tools/gen_arbres.py
# Sortie (assets/models/environnement/) :
#   arbre_chene.glb     — grand feuillu, canopée large
#   arbre_erable.glb    — feuillu plus petit et plus dense
#   arbre_pin.glb       — conifère, silhouette verticale
#   arbre_bouleau.glb   — élancé, écorce pâle, feuillage aéré
#   buisson.glb         — pour les sous-bois et les bords de maison

import bpy
import math
import os
import random
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import (
	boule, branche, cylindre, boite, vider_la_scene, exporter,
)

SOUS_DOSSIER = "environnement"


# ──────────────────────────────────────────────────────────────────────────────
# MORCEAUX COMMUNS
# ──────────────────────────────────────────────────────────────────────────────


def racines(rayon_tronc, couleur, nombre=6, longueur=1.0, hauteur=0.9):
	"""L'empattement : des contreforts qui partent du tronc et plongent au sol.

	Chacun va d'un point HAUT sur le tronc vers un point BAS et ÉLOIGNÉ : c'est
	cette diagonale qui donne l'impression que l'arbre est ancré.
	"""
	depart_angle = random.uniform(0, math.tau)
	for i in range(nombre):
		a = depart_angle + i * math.tau / nombre + random.uniform(-0.25, 0.25)
		portee = longueur * random.uniform(0.55, 0.85)
		# Épaisse au départ, fine à l'arrivée : c'est un contrefort, pas une
		# patte. Avec un départ trop fin, l'arbre a l'air posé sur des échasses.
		branche(
			f"Racine_{i}",
			(0, 0, hauteur * random.uniform(0.55, 0.85)),
			(math.cos(a) * (rayon_tronc + portee),
			 math.sin(a) * (rayon_tronc + portee),
			 0.0),
			rayon_tronc * 0.80,
			rayon_tronc * 0.30,
			couleur,
			segments=5,
		)


def tronc_courbe(hauteur, rayon_bas, rayon_haut, couleur, segments_verticaux=4,
				 courbure=0.12):
	"""Un tronc en plusieurs segments empilés, qui dérive légèrement.

	Un tronc parfaitement droit se lit comme un cylindre. Trois ou quatre
	segments qui partent un peu de travers se lisent comme un arbre.
	Renvoie le sommet du tronc — le point d'où partiront les branches.
	"""
	sommet = Vector((0, 0, 0))
	direction = Vector((random.uniform(-courbure, courbure),
						random.uniform(-courbure, courbure),
						1.0)).normalized()

	for i in range(segments_verticaux):
		t0 = i / segments_verticaux
		t1 = (i + 1) / segments_verticaux
		r0 = rayon_bas + (rayon_haut - rayon_bas) * t0
		r1 = rayon_bas + (rayon_haut - rayon_bas) * t1
		suivant = sommet + direction * (hauteur / segments_verticaux)
		branche(f"Tronc_{i}", sommet, suivant, r0, r1, couleur, segments=8)
		sommet = suivant
		# La direction dérive un peu plus à chaque étage.
		direction = (direction + Vector((random.uniform(-courbure, courbure),
										 random.uniform(-courbure, courbure),
										 0.0))).normalized()
	return sommet


def grappe_de_feuilles(centre, rayon, teintes, nombre=4):
	"""Une masse de feuillage = plusieurs boules imbriquées, pas une seule.

	Les tailles et les teintes varient : c'est ce qui casse la lecture
	« sphère » et donne du volume.
	"""
	for i in range(nombre):
		decalage = Vector((
			random.uniform(-rayon * 0.5, rayon * 0.5),
			random.uniform(-rayon * 0.5, rayon * 0.5),
			random.uniform(-rayon * 0.3, rayon * 0.7),
		))
		boule(
			f"Feuilles_{i}",
			rayon * random.uniform(0.55, 1.0),
			Vector(centre) + decalage,
			random.choice(teintes),
			aplatissement=random.uniform(0.80, 1.05),
			subdivisions=1,
			rotation=(0, 0, random.uniform(0, math.tau)),
		)


def ramure(sommet_tronc, rayon_sommet, couleur_bois, teintes_feuilles,
		   nombre=5, portee=2.6, montee=1.6, rayon_feuillage=1.5, etages=1):
	"""Les branches maîtresses + leur feuillage au bout.

	Chaque branche se divise une fois : deux brindilles, chacune avec sa
	grappe. C'est la division qui fait « arbre » plutôt que « parasol ».

	`etages` = 2 ajoute une seconde couronne, plus courte et plus haute. Sans
	elle, toutes les grappes sont à la même altitude et la canopée est plate
	comme un parasol.
	"""
	base_angle = random.uniform(0, math.tau)
	for i in range(nombre):
		a = base_angle + i * math.tau / nombre + random.uniform(-0.35, 0.35)
		# La branche part d'un point du tronc, plus ou moins haut.
		depart = Vector(sommet_tronc) + Vector((0, 0, random.uniform(-1.4, 0.2)))
		d = portee * random.uniform(0.8, 1.25)
		bout = depart + Vector((math.cos(a) * d, math.sin(a) * d,
								montee * random.uniform(0.7, 1.3)))
		branche(f"Branche_{i}", depart, bout,
				rayon_sommet * 0.55, rayon_sommet * 0.28, couleur_bois, segments=6)

		# Division en deux brindilles
		for j in range(2):
			ecart = 0.7 if j == 0 else -0.7
			bout2 = bout + Vector((
				math.cos(a + ecart) * d * 0.45,
				math.sin(a + ecart) * d * 0.45,
				montee * 0.5,
			))
			branche(f"Brindille_{i}_{j}", bout, bout2,
					rayon_sommet * 0.26, rayon_sommet * 0.12, couleur_bois, segments=5)
			grappe_de_feuilles(bout2, rayon_feuillage * random.uniform(0.8, 1.15),
							   teintes_feuilles, nombre=3)

	# Second étage : des branches plus courtes et plus redressées, qui posent
	# le dôme au-dessus de la première couronne.
	if etages >= 2:
		for i in range(nombre - 1):
			a = base_angle + 0.5 + i * math.tau / (nombre - 1) + random.uniform(-0.3, 0.3)
			depart = Vector(sommet_tronc) + Vector((0, 0, montee * random.uniform(0.3, 0.7)))
			d = portee * random.uniform(0.45, 0.7)
			bout = depart + Vector((math.cos(a) * d, math.sin(a) * d,
									montee * random.uniform(1.1, 1.6)))
			branche(f"BrancheHaute_{i}", depart, bout,
					rayon_sommet * 0.36, rayon_sommet * 0.16, couleur_bois, segments=5)
			grappe_de_feuilles(bout, rayon_feuillage * random.uniform(0.65, 0.95),
							   teintes_feuilles, nombre=3)

	# Une grappe centrale qui relie le tout, sinon la canopée a un trou au milieu.
	grappe_de_feuilles(Vector(sommet_tronc) + Vector((0, 0, montee * 1.25)),
					   rayon_feuillage * 1.25, teintes_feuilles, nombre=4)


# ──────────────────────────────────────────────────────────────────────────────
# LES ESSENCES
# ──────────────────────────────────────────────────────────────────────────────

TEINTES_FEUILLU = ["feuille", "feuille_clair", "feuille_sombre"]


def chene():
	"""Grand feuillu : tronc épais, canopée large et haute. ~9 m."""
	racines(0.45, "ecorce", nombre=7, longueur=1.1, hauteur=1.0)
	sommet = tronc_courbe(5.2, 0.45, 0.26, "ecorce", segments_verticaux=4, courbure=0.10)
	ramure(sommet, 0.26, "ecorce", TEINTES_FEUILLU,
		   nombre=6, portee=2.7, montee=2.0, rayon_feuillage=1.7, etages=2)


def erable():
	"""Feuillu plus petit et plus rond, pour varier la forêt. ~6 m."""
	racines(0.32, "ecorce", nombre=5, longueur=0.8, hauteur=0.7)
	sommet = tronc_courbe(3.4, 0.32, 0.19, "ecorce", segments_verticaux=3, courbure=0.16)
	ramure(sommet, 0.19, "ecorce", TEINTES_FEUILLU,
		   nombre=5, portee=1.9, montee=1.5, rayon_feuillage=1.35, etages=2)


def pin():
	"""Conifère : tronc droit et haut, étages de branches décroissants. ~11 m."""
	racines(0.34, "ecorce", nombre=5, longueur=0.7, hauteur=0.8)
	sommet = tronc_courbe(9.0, 0.38, 0.10, "ecorce", segments_verticaux=5, courbure=0.05)

	# Les étages : des cônes aplatis de plus en plus petits en montant.
	etages = 7
	for i in range(etages):
		t = i / (etages - 1.0)
		z = 2.2 + t * 7.2
		rayon = 2.5 * (1.0 - t) ** 0.85 + 0.35
		# Chaque étage est un cône très aplati, légèrement tourné.
		cylindre(
			f"Etage_{i}",
			rayon,
			rayon * 0.15,
			1.5 - t * 0.7,
			(sommet.x * t * 0.4, sommet.y * t * 0.4, z),
			"aiguille" if i % 2 == 0 else "feuille_sombre",
			segments=7,
			rotation=(0, 0, random.uniform(0, math.tau)),
		)
	# La flèche du sommet
	cylindre("Fleche", 0.45, 0.02, 1.6, (sommet.x, sommet.y, 9.3), "aiguille", segments=6)


def bouleau():
	"""Élancé, écorce pâle, feuillage léger et haut perché. ~8 m."""
	racines(0.22, "ecorce_pale", nombre=4, longueur=0.5, hauteur=0.5)
	sommet = tronc_courbe(6.0, 0.24, 0.13, "ecorce_pale", segments_verticaux=4, courbure=0.09)

	# Les marques sombres caractéristiques de l'écorce de bouleau.
	for i in range(14):
		z = random.uniform(0.6, 5.6)
		a = random.uniform(0, math.tau)
		r = 0.24 + (0.13 - 0.24) * (z / 6.0)
		boite(
			f"Marque_{i}",
			(random.uniform(0.12, 0.30), 0.04, random.uniform(0.04, 0.09)),
			(math.cos(a) * r, math.sin(a) * r, z),
			"ecorce",
			rotation=(0, 0, a),
			biseau=0.01,
		)

	ramure(sommet, 0.13, "ecorce_pale", ["feuille_clair", "feuille"],
		   nombre=5, portee=1.5, montee=2.3, rayon_feuillage=1.05, etages=2)


def buisson():
	"""Sous-bois : quelques grappes basses sur des tiges courtes. ~1,2 m."""
	for i in range(5):
		a = random.uniform(0, math.tau)
		d = random.uniform(0.0, 0.45)
		depart = Vector((math.cos(a) * d, math.sin(a) * d, 0.0))
		bout = depart + Vector((random.uniform(-0.3, 0.3),
								random.uniform(-0.3, 0.3),
								random.uniform(0.45, 0.8)))
		branche(f"Tige_{i}", depart, bout, 0.07, 0.04, "ecorce", segments=4)
		grappe_de_feuilles(bout, random.uniform(0.5, 0.75),
						   ["feuille", "feuille_clair", "mousse"], nombre=3)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	# Une graine par essence : les arbres ne changent pas d'une régénération à
	# l'autre, sinon impossible de comparer deux captures.
	for nom_fichier, graine, fabrique in [
		("arbre_chene.glb",   101, chene),
		("arbre_erable.glb",  202, erable),
		("arbre_pin.glb",     303, pin),
		("arbre_bouleau.glb", 404, bouleau),
		("buisson.glb",       505, buisson),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		exporter(SOUS_DOSSIER, nom_fichier)
