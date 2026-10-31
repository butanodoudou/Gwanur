# tools/gen_aelith_v2.py — L'Aelith, l'Arbre-Monde de Sylvara
#
# Remplace `gen_aelith.py` (l'Aelith « v4 », un arbre classique de 13 m dont le
# .glb n'a jamais été branché dans la scène — c'est le saule `nimbus_willow`
# qui était utilisé). L'ancien script est conservé tel quel : on n'écrase pas
# un design, on en propose un autre à côté.
#
# L'IDÉE : le village n'est pas AU PIED de l'Aelith, il est DEDANS.
# L'arbre est si vieux et si vaste que son tronc s'est creusé, et Sylvara
# s'est installée dans la cavité. La paroi de bois qui entoure le village
# est le rempart naturel du lieu — personne n'attaque un village qui n'a que
# deux ouvertures dans une muraille vivante de quarante mètres.
#
# CONSÉQUENCES DE CE CHOIX (assumées, à relire dans docs/DECISIONS.md)
#   - Il n'y a PAS de tronc au centre du village : le centre, c'est la place.
#     C'est ce qui rend l'idée jouable — un tronc de 18 m de diamètre au
#     milieu écraserait le puits, Vaenmor et la moitié des chemins.
#   - Le ciel est visible par un OCULUS : la canopée s'écarte au-dessus du
#     centre. Sans ça le village serait dans le noir, et le jeu est Ghibli,
#     pas souterrain.
#   - Les deux ouvertures de la paroi tombent pile sur l'entrée sud et sur la
#     sortie nord (après la Porte Double du Puzzle 1). La géométrie sert la
#     progression au lieu de la contrarier.
#
# REPÈRE D'ANGLE
# On raisonne en angles « à la Godot » : θ = 0 pointe vers le SUD (+Z de
# Godot), θ = π vers le NORD. `_vers(θ, rayon)` fait la conversion vers les
# axes de Blender, où le sud est -Y.
#
# Usage :
#   blender --background --python tools/gen_aelith_v2.py
# Sortie :
#   assets/models/environnement/aelith_paroi.glb    — la muraille vivante
#   assets/models/environnement/aelith_canopee.glb  — branches et feuillage

import bpy
import math
import os
import random
import sys
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import (
	boule, branche, cylindre, vider_la_scene, exporter, marquer_grappe,
)


def grappe(*args, **kwargs):
	"""Une boule de feuillage aux normales sphériques (voir marquer_grappe) :
	elle s'éclaire comme une masse douce, pas comme une boule à facettes."""
	objet = boule(*args, **kwargs)
	marquer_grappe(objet, kwargs.get("aplatissement", 1.0))
	return objet

SOUS_DOSSIER = "environnement"

# ── Dimensions ────────────────────────────────────────────────────────────────
# Tout part de RAYON_INTERIEUR : c'est lui qui doit contenir la zone jouable
# (le village va jusqu'à ~z=-62 au nord, ~z=+37 au sud, ±52 en largeur).
RAYON_INTERIEUR = 56.0
EPAISSEUR       = 11.0    # épaisseur moyenne de la paroi de bois
HAUTEUR_PAROI   = 62.0    # hauteur du rempart
COLONNES        = 84      # fibres verticales qui composent la paroi

# Les ouvertures, en angles Godot : (centre, demi-largeur) en radians.
# 0 = sud (l'entrée du village), π = nord (la sortie vers la Zone 2).
OUVERTURES = [
	(0.0,            0.085),   # entrée sud
	(math.pi,        0.075),   # sortie nord, derrière la Porte Double
	(math.pi * 0.5,  0.045),   # brèche est — laisse entrer le soleil du matin
	(-math.pi * 0.5, 0.045),   # brèche ouest
]


def _vers(angle, rayon):
	"""Angle Godot + rayon → coordonnées Blender (x, y).

	Godot : x = sin θ, z = cos θ.  Blender : x = sin θ, y = -cos θ.
	"""
	return (math.sin(angle) * rayon, -math.cos(angle) * rayon)


def _dans_une_ouverture(angle):
	for centre, demi in OUVERTURES:
		ecart = abs(math.atan2(math.sin(angle - centre), math.cos(angle - centre)))
		if ecart < demi:
			return True
	return False


# ──────────────────────────────────────────────────────────────────────────────
# LA PAROI — le tronc creux
# ──────────────────────────────────────────────────────────────────────────────


def paroi():
	"""La muraille de bois vivant, faite de fibres verticales accolées.

	Une paroi lisse se lirait comme un mur de béton peint en brun. Des fibres
	de largeurs et de hauteurs différentes, chacune un peu penchée, donnent la
	texture torsadée d'un très vieux tronc.
	"""
	for i in range(COLONNES):
		angle = i * math.tau / COLONNES
		if _dans_une_ouverture(angle):
			continue

		# Les fibres s'amincissent et se rapprochent du centre en montant :
		# la cavité s'ouvre vers le ciel comme une corolle.
		epaisseur = EPAISSEUR * random.uniform(0.75, 1.25)
		hauteur = HAUTEUR_PAROI * random.uniform(0.90, 1.12)
		rayon_bas = RAYON_INTERIEUR + epaisseur * 0.5
		# Évasement quasi identique pour toutes : si chaque fibre s'écarte d'une
		# valeur différente, elles divergent en montant et la paroi se
		# transforme en alignement de piliers séparés.
		rayon_haut = rayon_bas + 4.5 + random.uniform(-0.6, 0.6)

		bx, by = _vers(angle, rayon_bas)
		hx, hy = _vers(angle + random.uniform(-0.02, 0.02), rayon_haut)

		# Une fibre sur trois est sombre et légèrement en retrait : ce sont les
		# sillons. Sans eux la paroi est une surface unie, et 60 m de surface
		# unie se lisent comme du béton, pas comme du bois.
		sombre = (i % 3 == 1)
		# Et une sur cinq est plus claire, dorée : la crête qui prend le soleil.
		# Trois valeurs au lieu de deux, c'est ce qui donne du relief à 60 m.
		teinte = "ecorce_aelith"
		if sombre:
			teinte = "ecorce_aelith_sombre"
		elif i % 5 == 0:
			teinte = "ecorce_aelith_doree"
		branche(
			f"Fibre_{i}",
			(bx, by, -2.0),
			(hx, hy, hauteur),
			epaisseur * (0.58 if sombre else 0.72),
			epaisseur * (0.40 if sombre else 0.52),
			teinte,
			segments=6,
		)

		# Contrefort : chaque fibre s'ancre au sol par une racine qui plonge
		# vers l'intérieur du village. C'est ce qui relie la muraille au sol.
		if i % 2 == 0:
			ix, iy = _vers(angle + random.uniform(-0.03, 0.03),
						   RAYON_INTERIEUR - random.uniform(4.0, 11.0))
			branche(
				f"Contrefort_{i}",
				(bx, by, random.uniform(6.0, 14.0)),
				(ix, iy, 0.0),
				epaisseur * 0.40,
				epaisseur * 0.13,
				"ecorce_aelith",
				segments=5,
			)

	# Le bourrelet du sol : un anneau de bois épais à la base, pour que la
	# paroi ne sorte pas de terre comme une palissade plantée.
	for i in range(COLONNES):
		angle = i * math.tau / COLONNES
		if _dans_une_ouverture(angle):
			continue
		bx, by = _vers(angle, RAYON_INTERIEUR + EPAISSEUR * 0.35)
		boule(
			f"Bourrelet_{i}",
			random.uniform(5.0, 8.0),
			(bx, by, random.uniform(-1.0, 1.5)),
			"ecorce_aelith",
			aplatissement=random.uniform(0.35, 0.55),
			subdivisions=1,
		)

	# ── L'écosystème sur la paroi ────────────────────────────────────────────
	# L'arbre est si vaste qu'une forêt pousse sur lui. Des grappes de mousse
	# et de feuillage accrochées à la muraille, à toutes les hauteurs.
	for i in range(90):
		angle = random.uniform(0, math.tau)
		if _dans_une_ouverture(angle):
			continue
		z = random.uniform(3.0, HAUTEUR_PAROI * 0.95)
		# Plus on monte, plus la paroi est loin du centre (elle s'évase).
		rayon = RAYON_INTERIEUR + (z / HAUTEUR_PAROI) * 4.0 - random.uniform(1.0, 4.0)
		x, y = _vers(angle, rayon)
		grappe(
			f"Mousse_{i}",
			random.uniform(1.8, 5.0),
			(x, y, z),
			random.choice(["mousse", "feuille", "feuille_sombre"]),
			aplatissement=random.uniform(0.4, 0.7),
			subdivisions=2,  # 320 faces : une silhouette ronde, pas un hexagone
			rotation=(0, 0, random.uniform(0, math.tau)),
		)

	# Quelques arbres entiers poussent sur les corniches de la muraille.
	for i in range(14):
		angle = random.uniform(0, math.tau)
		if _dans_une_ouverture(angle):
			continue
		z = random.uniform(12.0, HAUTEUR_PAROI * 0.9)
		x, y = _vers(angle, RAYON_INTERIEUR - 1.0)
		# Un tronc court, penché vers le vide, et sa couronne.
		bout = Vector((x * 0.94, y * 0.94, z + random.uniform(5.0, 9.0)))
		branche(f"ArbrePerche_{i}", (x, y, z), bout, 0.7, 0.35, "ecorce", segments=5)
		for j in range(4):
			grappe(
				f"CouronnePerchee_{i}_{j}",
				random.uniform(1.8, 3.2),
				bout + Vector((random.uniform(-2, 2), random.uniform(-2, 2),
							   random.uniform(-0.5, 2.0))),
				random.choice(["feuille", "feuille_clair"]),
				aplatissement=0.85,
				subdivisions=2,
			)

	# Des lianes qui pendent le long de la paroi — l'échelle se lit dans ces
	# détails verticaux autant que dans la hauteur elle-même.
	for i in range(40):
		angle = random.uniform(0, math.tau)
		if _dans_une_ouverture(angle):
			continue
		z = random.uniform(15.0, HAUTEUR_PAROI)
		x, y = _vers(angle, RAYON_INTERIEUR - random.uniform(0.5, 3.0))
		chute = random.uniform(8.0, 26.0)
		branche(f"Liane_{i}", (x, y, z), (x * 0.97, y * 0.97, z - chute),
				0.22, 0.10, "feuille_sombre", segments=4)


# ──────────────────────────────────────────────────────────────────────────────
# LA CANOPÉE — branches et feuillage, très haut
# ──────────────────────────────────────────────────────────────────────────────

BASE_BRANCHES = HAUTEUR_PAROI - 4.0
RAYON_OCULUS  = 18.0     # le trou de ciel au-dessus de la place


def canopee():
	"""Les branches partent du haut de la paroi, montent, et se rejoignent en
	voûte — sans jamais refermer le centre : l'oculus laisse passer le jour.
	"""
	nombre = 16
	for i in range(nombre):
		angle = i * math.tau / nombre + random.uniform(-0.06, 0.06)
		rayon_depart = RAYON_INTERIEUR + 3.0
		dx, dy = _vers(angle, rayon_depart)
		depart = Vector((dx, dy, BASE_BRANCHES))

		# La branche maîtresse monte en s'écartant un peu vers l'extérieur.
		hauteur_1 = random.uniform(42.0, 62.0)
		mx, my = _vers(angle + random.uniform(-0.12, 0.12), rayon_depart + random.uniform(6, 16))
		milieu = Vector((mx, my, BASE_BRANCHES + hauteur_1))
		branche(f"Maitresse_{i}", depart, milieu, 6.5, 3.4, "ecorce_aelith", segments=8)

		# Puis elle se recourbe vers l'intérieur, en voûte au-dessus du village.
		portee = rayon_depart - RAYON_OCULUS - random.uniform(0.0, 12.0)
		sx, sy = _vers(angle + random.uniform(-0.2, 0.2), rayon_depart - portee)
		sommet = Vector((sx, sy, BASE_BRANCHES + hauteur_1 + random.uniform(24.0, 40.0)))
		branche(f"Voute_{i}", milieu, sommet, 3.4, 1.4, "ecorce_aelith", segments=7)

		# Feuillage : de grosses masses le long de la voûte, pas au bout.
		for t in (0.35, 0.65, 0.95):
			centre = milieu.lerp(sommet, t)
			for j in range(4):
				grappe(
					f"Feuillage_{i}_{t}_{j}",
					random.uniform(6.0, 11.0),
					centre + Vector((random.uniform(-6, 6), random.uniform(-6, 6),
									 random.uniform(-3, 6))),
					random.choice(["feuille_or", "feuille", "feuille_clair"]),
					aplatissement=random.uniform(0.80, 1.0),
					subdivisions=2,
					rotation=(0, 0, random.uniform(0, math.tau)),
				)

		# Une branche secondaire qui part vers l'extérieur : vue de l'intérieur
		# du village on ne la voit pas, mais elle donne sa silhouette à l'arbre
		# quand on l'aperçoit de loin.
		ex, ey = _vers(angle + random.uniform(-0.25, 0.25), rayon_depart + random.uniform(14, 28))
		exterieur = Vector((ex, ey, BASE_BRANCHES + hauteur_1 + random.uniform(-6.0, 10.0)))
		branche(f"Exterieure_{i}", milieu, exterieur, 3.0, 1.2, "ecorce_aelith", segments=6)
		for j in range(3):
			grappe(
				f"FeuillageExt_{i}_{j}",
				random.uniform(8.0, 14.0),
				exterieur + Vector((random.uniform(-7, 7), random.uniform(-7, 7),
									random.uniform(-2, 7))),
				random.choice(["feuille_or", "feuille"]),
				aplatissement=random.uniform(0.82, 1.0),
				subdivisions=2,
			)

		# Du feuillage sous la pointe de la voûte : vu du village, c'est LUI
		# qui fait le plafond. Sans lui, la canopée n'existe qu'à l'extérieur
		# et le village a l'air posé au fond d'un cratère de piliers.
		for j in range(3):
			grappe(
				f"FeuillageInterieur_{i}_{j}",
				random.uniform(9.0, 15.0),
				sommet + Vector((random.uniform(-8, 8), random.uniform(-8, 8),
								 random.uniform(-2, 8))),
				random.choice(["feuille_or", "feuille_clair", "feuille"]),
				aplatissement=random.uniform(0.7, 0.95),
				subdivisions=2,
			)

		# Lianes tombant de la voûte vers le village — l'échelle, encore.
		for j in range(2):
			t = random.uniform(0.3, 0.9)
			accroche = milieu.lerp(sommet, t)
			branche(f"LianeHaute_{i}_{j}", accroche,
					accroche - Vector((0, 0, random.uniform(14.0, 34.0))),
					0.30, 0.12, "feuille_sombre", segments=4)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	for nom_fichier, graine, fabrique in [
		("aelith_paroi.glb",   777, paroi),
		("aelith_canopee.glb", 888, canopee),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		exporter(SOUS_DOSSIER, nom_fichier)
