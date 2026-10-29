# tools/gen_pnj.py — les villageois de Sylvara
#
# Remplace les capsules colorées de `scripts/npcs/pnj.gd`.
#
# QUATRE SILHOUETTES POUR NEUF VILLAGEOIS
# À 9 m (la distance de la caméra), on reconnaît quelqu'un à sa silhouette et
# à sa couleur, pas à son visage. D'où quatre corps très différents :
#   - pnj_ancien.glb      : voûté, barbe blanche, longue robe, bâton
#                           (Vaenmor, Caeryn)
#   - pnj_villageois.glb  : solide, tablier, chapeau de feutre
#                           (Brennan, Eldwen, Tovan)
#   - pnj_villageoise.glb : robe longue évasée, tablier, chignon, foulard
#                           (Lira, Marnen, Nyssil)
#   - pnj_enfant.glb      : petit, grosse tête, deux couettes (Soraï)
# Le choix d'une silhouette par PNJ est fait dans pnj.gd.
#
# UNE COULEUR PAR PNJ, SANS UN .GLB PAR PNJ
# La tunique (et la robe) utilise un matériau nommé `tunique_pnj`, de couleur
# neutre. Godot cherche ce NOM dans le modèle et le remplace par la couleur
# propre à chaque villageois (la propriété `couleur` de pnj.gd, déjà réglée
# dans zone1.tscn). Le nom du matériau est donc un contrat entre ce script et
# pnj.gd : ne pas le renommer.
#
# Le corps vient de `gen_personnages.py` (même style que Kael et Mira) : on
# importe ses fonctions et on change seulement la taille et les vêtements.
#
# ORIENTATION : comme les héros, les PNJ regardent -Y dans Blender = +Z dans
# Godot (le sud, l'entrée du village). L'origine est AUX PIEDS : la
# respiration procédurale (scale Y) reste ainsi ancrée au sol.
#
# Usage :
#   blender --background --python tools/gen_pnj.py
# Sortie :
#   assets/models/personnages/pnj_*.glb

import bpy
import math
import os
import random
import sys
from mathutils import Matrix, Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from blender_commun import boite, boule, cylindre, branche, vider_la_scene, exporter
import gen_personnages as gp

SOUS_DOSSIER = "personnages"
TUNIQUE = "tunique_pnj"


def h(fraction):
	# On passe par le module : sa TAILLE change selon la silhouette.
	return gp.TAILLE * fraction


def _pencher_le_haut_du_corps(angle, pivot_z):
	"""Fait pivoter tout ce qui est au-dessus du bassin, vers l'avant (-Y).

	C'est le dos voûté de l'ancien. Angle positif = vers l'avant. Axe horizontal
	(X) qui passe par le bassin ; les jambes restent droites.
	"""
	# ⚠ matrix_world n'est recalculée qu'à la mise à jour de la scène : sans
	# cet appel, elle vaut encore l'identité pour les objets tout juste créés,
	# et tout le haut du corps se retrouve empilé à l'origine.
	bpy.context.view_layer.update()
	pivot = Vector((0, 0, pivot_z))
	rotation = (Matrix.Translation(pivot)
				@ Matrix.Rotation(angle, 4, "X")
				@ Matrix.Translation(-pivot))
	for objet in bpy.data.objects:
		if objet.name.startswith(("Cuisse", "Mollet", "Botte", "Robe", "Baton")):
			continue
		objet.matrix_world = rotation @ objet.matrix_world


# ──────────────────────────────────────────────────────────────────────────────
# L'ANCIEN — Vaenmor (« barbe cendre-vieux »), Caeryn le vieux forgeron
# ──────────────────────────────────────────────────────────────────────────────


def ancien():
	gp.TAILLE = 1.68
	gp.corps(carrure=1.0, couleur_tunique=TUNIQUE, jupe=True)
	gp.cheveux("cheveux_blanc", longueur=0.08)

	# La barbe : c'est SA silhouette, elle doit déborder du menton.
	branche("Barbe", (0, -0.085, h(gp.Y_TETE) - 0.005), (0, -0.115, h(0.72)),
			0.085, 0.025, "cheveux_blanc", segments=6)
	boule("Moustache", 0.06, (0, -0.105, h(gp.Y_TETE) + 0.005), "cheveux_blanc",
		  aplatissement=0.5, subdivisions=1)

	# Une étole de lin sur les épaules, qui casse la ligne de la robe.
	cylindre("Etole", 0.20, 0.13, 0.12, (0, 0, h(0.74)), "lin", segments=10)

	# Le dos se voûte de 20° autour du bassin. Fait AVANT la robe et le
	# bâton, qui restent verticaux.
	_pencher_le_haut_du_corps(math.radians(20), h(gp.Y_BASSIN))

	# La robe longue, jusqu'aux chevilles : une cloche de tissu.
	branche("Robe", (0, 0, h(0.52)), (0, 0.02, h(0.05)),
			0.17, 0.25, TUNIQUE, segments=10)

	# Le bâton, planté devant lui, tenu par la main droite (qui s'est
	# avancée avec le buste).
	branche("Baton", (0.26, -0.06, h(0.52)), (0.30, -0.22, 0.0),
			0.022, 0.018, "bois_sombre", segments=5)
	boule("BatonPommeau", 0.035, (0.26, -0.06, h(0.53)), "bois_sombre", subdivisions=1)


# ──────────────────────────────────────────────────────────────────────────────
# LE VILLAGEOIS — Brennan le meunier, Eldwen le berger, Tovan le paysan
# ──────────────────────────────────────────────────────────────────────────────


def villageois():
	gp.TAILLE = 1.78
	gp.corps(carrure=1.18, couleur_tunique=TUNIQUE, jupe=True)
	gp.cheveux("cheveux_chatain", longueur=0.07)

	# Barbe courte, qui épaissit la mâchoire.
	boule("Barbe", 0.085, (0, -0.07, h(gp.Y_TETE) - 0.01), "cheveux_chatain",
		  aplatissement=0.8, subdivisions=1)

	# Tablier de cuir : une plaque devant, du torse aux genoux.
	boite("Tablier", (0.30, 0.04, 0.55), (0, -0.165, h(0.47)), "cuir",
		  rotation=(0.08, 0, 0), biseau=0.015)
	boite("TablierSangle", (0.04, 0.03, 0.18), (0, -0.16, h(0.73)), "cuir",
		  biseau=0.008)

	# Chapeau de feutre à large bord : de loin, on le reconnaît à ça.
	z_chapeau = h(gp.Y_TETE) + 0.12
	cylindre("ChapeauBord", 0.24, 0.23, 0.025, (0, 0, z_chapeau), "feutre", segments=12)
	cylindre("ChapeauCalotte", 0.13, 0.11, 0.12, (0, 0, z_chapeau), "feutre", segments=10)
	cylindre("ChapeauRuban", 0.132, 0.132, 0.03, (0, 0, z_chapeau + 0.02), "lin", segments=10)

	# Une besace à la hanche.
	boite("Besace", (0.16, 0.08, 0.15), (0.22, 0.02, h(0.47)), "cuir", biseau=0.02)


# ──────────────────────────────────────────────────────────────────────────────
# LA VILLAGEOISE — Lira, Marnen, Nyssil la tisserande
# ──────────────────────────────────────────────────────────────────────────────


def villageoise():
	gp.TAILLE = 1.66
	gp.corps(carrure=0.95, couleur_tunique=TUNIQUE, jupe=False)
	gp.cheveux("cheveux_roux", longueur=0.09)

	# La robe : une grande cloche de la taille aux chevilles. Elle cache les
	# jambes — c'est elle qui fait la silhouette.
	branche("Robe", (0, 0, h(0.58)), (0, 0.01, h(0.03)),
			0.15, 0.29, TUNIQUE, segments=12)
	# Un ourlet plus sombre en bas de robe.
	cylindre("Ourlet", 0.295, 0.29, 0.05, (0, 0.01, h(0.03)), "cuir", segments=12)

	# Tablier de lin, plus clair que la robe : il se lit sur toutes les teintes.
	boite("Tablier", (0.26, 0.03, 0.48), (0, -0.175, h(0.36)), "lin",
		  rotation=(0.18, 0, 0), biseau=0.012)
	cylindre("Ceinture", 0.155, 0.155, 0.04, (0, 0, h(0.57)), "lin", segments=10)

	# Le chignon, derrière la tête.
	boule("Chignon", 0.075, (0, 0.12, h(gp.Y_TETE) + 0.07), "cheveux_roux",
		  subdivisions=2)
	# Un foulard noué sur les épaules.
	cylindre("Foulard", 0.17, 0.10, 0.08, (0, 0, h(0.76)), "lin", segments=10)


# ──────────────────────────────────────────────────────────────────────────────
# L'ENFANT — Soraï
# ──────────────────────────────────────────────────────────────────────────────


def enfant():
	gp.TAILLE = 1.15
	# Les rayons de corps() sont en mètres absolus : à 1,15 m ils donnent
	# naturellement un enfant aux membres un peu épais et à la tête grosse —
	# exactement les proportions d'un enfant de film d'animation.
	gp.corps(carrure=0.78, couleur_tunique=TUNIQUE, jupe=True)
	gp.cheveux("cheveux_chatain", longueur=0.08)

	# Deux couettes qui dépassent sur les côtés.
	for cote in (-1, 1):
		branche("Couette", (cote * 0.10, 0.04, h(gp.Y_TETE) + 0.06),
				(cote * 0.19, 0.07, h(gp.Y_TETE) - 0.05),
				0.04, 0.02, "cheveux_chatain", segments=5)
	# Un col de lin, et une petite sacoche en bandoulière.
	cylindre("Col", 0.13, 0.10, 0.05, (0, 0, h(0.77)), "lin", segments=10)
	boite("Sacoche", (0.11, 0.05, 0.10), (-0.15, -0.03, h(0.50)), "cuir", biseau=0.015)
	boite("Bandouliere", (0.26, 0.04, 0.035), (0, -0.02, h(0.66)), "cuir",
		  rotation=(0, -0.6, 0), biseau=0.01)


# ──────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
	for nom_fichier, graine, fabrique in [
		("pnj_ancien.glb", 31, ancien),
		("pnj_villageois.glb", 32, villageois),
		("pnj_villageoise.glb", 33, villageoise),
		("pnj_enfant.glb", 34, enfant),
	]:
		vider_la_scene()
		random.seed(graine)
		fabrique()
		exporter(SOUS_DOSSIER, nom_fichier, lisse=False)
